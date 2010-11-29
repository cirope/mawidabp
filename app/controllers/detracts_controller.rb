# =Controlador de detractores
#
# Lista, muestra y crea detractores (#Detract)
class DetractsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges,
    :load_approval_privilege
  hide_action :load_privileges, :find_with_organization,
    :load_approval_privilege
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista los detractores
  #
  # * GET /detracts
  # * GET /detracts.xml
  def index
    @title = t :'detract.index_title'
    conditions = ["#{Organization.table_name}.id = :organization_id"]
    parameters = {:organization_id => @auth_organization.id}

    unless @has_approval
      conditions << "#{User.table_name}.id = :user_id"
      parameters[:user_id] = @auth_user
    end

    build_search_conditions User, [conditions.join(' AND '), parameters]

    @users = User.paginate(:page => params[:page],
      :include => :organizations,
      :conditions => @conditions,
      :per_page => APP_LINES_PER_PAGE,
      :order => [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ].join(', ')
    )

    respond_to do |format|
      format.html {
        if @users.size == 1 && (!@query.blank? || !@has_approval) &&
            !params[:page]

          redirect_to @has_approval ?
            new_detract_path(:detract => {:user_id => @users.first.id}) :
            {:action => :show, :id => @users.first.detracts.last || 0}
        end
      } # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # Muestra el detalle de un detractor
  #
  # * GET /detracts/1
  # * GET /detracts/1.xml
  def show
    @title = t :'detract.show_title'
    @detract = find_with_organization(params[:id])
    @user = @detract.try(:user) || (@auth_user unless @has_approval)

    if @user
      @detracts = @user.detracts.for_organization(@auth_organization).all(
        :limit => LAST_DETRACTORS_LIMIT, :order => 'created_at DESC')
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @detract }
    end
  end

  # Muestra los últimos detractores del usuario
  #
  # * GET /detracts/show_last_detracts/1
  # * GET /detracts/show_last_detracts/1.xml
  def show_last_detracts
    @user = User.find params[:id]

    conditions = {
      :organization_id => @auth_organization.id
    }

    unless @has_approval
      conditions["#{User.table_name}.id"] = @auth_user.child_ids |
        [@auth_user.id]
    end

    @detracts = @user.detracts.all(
      :include => {:user => :children},
      :conditions => conditions,
      :order => "#{Detract.table_name}.created_at DESC",
      :limit => LAST_DETRACTORS_LIMIT,
      :readonly => false
    )

    respond_to do |format|
      format.html { render :partial => 'show_last_detracts' }
      format.xml  { render :xml => @detracts }
    end
  end

  # Permite ingresar los datos para crear un nuevo detractor
  #
  # * GET /detracts/new
  # * GET /detracts/new.xml
  def new
    @title = t :'detract.new_title'
    @detract = Detract.new(params[:detract])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @detract }
    end
  end

  # Crea un detractor siempre que cumpla con las validaciones.
  #
  # POST /detracts
  # POST /detracts.xml
  def create
    @title = t :'detract.new_title'
    @detract = Detract.new(params[:detract])

    respond_to do |format|
      if @detract.save
        flash.notice = t :'detract.correctly_created'
        format.html { redirect_to(detracts_path) }
        format.xml  { render :xml => @detract, :status => :created, :location => @detract }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @detract.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  # Busca el detractor indicado siempre que pertenezca a la organización. En el
  # caso que no se encuentre (ya sea que no existe un detractor con ese ID o que
  # no pertenece a la organización con la que se autenticó el usuario) devuelve
  # nil.
  # _id_::  ID del periodo que se quiere recuperar
  def find_with_organization(id) #:doc:
    conditions = {:id => id.to_i, :organization_id => @auth_organization.id}

    unless @has_approval
      conditions["#{User.table_name}.id"] = @auth_user.id
    end

    Detract.first(
      :include => {:user => :children},
      :conditions => conditions,
      :readonly => false
    )
  end

  def load_privileges #:nodoc:
    if @action_privileges
      @action_privileges.update({
        :new => :approval,
        :create => :approval,
        :show_last_detracts => :read
      })
    end
  end

  def load_approval_privilege
    @has_approval = @auth_privileges[@current_module][:approval]
  end
end