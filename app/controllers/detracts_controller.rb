# =Controlador de detractores
#
# Lista, muestra y crea detractores (#Detract)
class DetractsController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges,
    :load_approval_privilege
  before_action :set_detract, only: [:show]
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista los detractores
  #
  # * GET /detracts
  # * GET /detracts.xml
  def index
    @title = t 'detract.index_title'

    unless @has_approval
      conditions = []
      parameters = {}

      conditions << "#{User.table_name}.id = :user_id"
      parameters[:user_id] = @auth_user
    
      build_search_conditions User, [conditions.join(' AND '), parameters]
    else
      build_search_conditions User
    end

    @users = User.includes(:organizations).where(@conditions).order(
      [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ]
    ).references(:organizations).paginate(page: params[:page], per_page: APP_LINES_PER_PAGE)

    respond_to do |format|
      format.html {
        if @users.size == 1 && (!@query.blank? || !@has_approval) &&
            !params[:page]

          redirect_to @has_approval ?
            new_detract_url(detract: {user_id: @users.first.id}) :
            {action: :show, id: @users.first.detracts.last || 0}
        end
      } # index.html.erb
      format.xml  { render xml: @users }
    end
  end

  # Muestra el detalle de un detractor
  #
  # * GET /detracts/1
  # * GET /detracts/1.xml
  def show
    @title = t 'detract.show_title'
    @user = @detract.try(:user) || (@auth_user unless @has_approval)

    if @user
      @detracts = @user.detracts.order(
        'created_at DESC
      ').limit(LAST_DETRACTORS_LIMIT)
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @detract }
    end
  end

  # Muestra los últimos detractores del usuario
  #
  # * GET /detracts/show_last_detracts/1
  # * GET /detracts/show_last_detracts/1.xml
  def show_last_detracts
    @user = User.find params[:id]

    conditions = {}

    unless @has_approval
      conditions["#{User.table_name}.id"] = @auth_user.child_ids |
        [@auth_user.id]
    end

    @detracts = @user.detracts.includes(
      user: :children
    ).where(conditions).order("#{Detract.table_name}.created_at DESC").limit(
      LAST_DETRACTORS_LIMIT
    ).references(:user)

    respond_to do |format|
      format.html { render '_show_last_detracts' }
      format.xml  { render xml: @detracts }
    end
  end

  # Permite ingresar los datos para crear un nuevo detractor
  #
  # * GET /detracts/new
  # * GET /detracts/new.xml
  def new
    @title = t 'detract.new_title'
    @detract = Detract.new(detract_params)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @detract }
    end
  end

  # Crea un detractor siempre que cumpla con las validaciones.
  #
  # POST /detracts
  # POST /detracts.xml
  def create
    @title = t 'detract.new_title'
    @detract = Detract.new(detract_params)

    respond_to do |format|
      if @detract.save
        flash.notice = t 'detract.correctly_created'
        format.html { redirect_to(detracts_url) }
        format.xml  { render xml: @detract, status: :created, location: @detract }
      else
        format.html { render action: :new }
        format.xml  { render xml: @detract.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_detract
      unless @has_approval
        @detract = Detract.includes(:user => :children).where(
          "#{User.table_name}.id = :user_id", @auth_user.id
        ).first
      else
        @detract = Detract.find(params[:id])
      end
    end

    def detract_params
      params.require(:detract).permit(:value, :observations, :user_id, :lock_version)
    end

    def load_privileges
      if @action_privileges
        @action_privileges.update({
          new: :approval,
          create: :approval,
          show_last_detracts: :read
        })
      end
    end

    def load_approval_privilege
      @has_approval = @auth_privileges[@current_module][:approval]
    end
end
