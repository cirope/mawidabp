# =Controlador de grupos
#
# Lista, muestra, crea, modifica y elimina grupos (#Group)
class GroupsController < ApplicationController
  layout 'clean'
  before_action :auth, :check_group_admin

  # Lista los grupos
  #
  # * GET /groups
  # * GET /groups.xml
  def index
    @title = t 'group.index_title'
    @groups = Group.order('name ASC').paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # Muestra el detalle de un grupo
  #
  # * GET /groups/1
  # * GET /groups/1.xml
  def show
    @title = t 'group.show_title'
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # Permite ingresar los datos para crear un nuevo grupo
  #
  # * GET /groups/new
  # * GET /groups/new.xml
  def new
    @title = t 'group.new_title'
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group }
    end
  end

  # Recupera los datos para modificar un grupo
  #
  # * GET /groups/1/edit
  def edit
    @title = t 'group.edit_title'
    @group = Group.find(params[:id])
  end

  # Crea una nuevo grupo siempre que cumpla con las validaciones
  #
  # * POST /groups
  # * POST /groups.xml
  def create
    @title = t 'group.new_title'
    @group = Group.new(group_params)

    respond_to do |format|
      if @group.save
        flash.notice = t 'group.correctly_created'
        format.html { redirect_to(groups_url) }
        format.xml  { render :xml => @group, :status => :created, :location => @group }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un grupo siempre que cumpla con las validaciones
  #
  # * PATCH /groups/1
  # * PATCH /groups/1.xml
  def update
    @title = t 'group.edit_title'
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update(group_params)
        flash.notice = t 'group.correctly_updated'
        format.html { redirect_to(groups_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'group.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina un grupo
  #
  # * DELETE /groups/1
  # * DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
    end
  end

  private

  def group_params
    params.require(:group).permit(
      :name, :description, :admin_email, :send_notification_email,
      :lock_version,
      organizations_attributes: [:id, :name, :prefix, :description]
    )
  end
end
