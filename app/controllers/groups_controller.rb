# =Controlador de grupos
#
# Lista, muestra, crea, modifica y elimina grupos (#Group)
class GroupsController < ApplicationController
  layout 'clean'
  before_action :auth, :check_group_admin

  # Lista los grupos
  #
  # * GET /groups
  def index
    @title = t 'group.index_title'
    @groups = Group.order(name: :asc).page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # Muestra el detalle de un grupo
  #
  # * GET /groups/1
  def show
    @title = t 'group.show_title'
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # Permite ingresar los datos para crear un nuevo grupo
  #
  # * GET /groups/new
  def new
    @title = t 'group.new_title'
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
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
  def create
    @title = t 'group.new_title'
    @group = Group.new(group_params)

    respond_to do |format|
      if @group.save
        flash.notice = t 'group.correctly_created'
        format.html { redirect_to(groups_url) }
      else
        format.html { render :action => :new }
      end
    end
  end

  # Actualiza el contenido de un grupo siempre que cumpla con las validaciones
  #
  # * PATCH /groups/1
  def update
    @title = t 'group.edit_title'
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update(group_params)
        flash.notice = t 'group.correctly_updated'
        format.html { redirect_to(groups_url) }
      else
        format.html { render :action => :edit }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'group.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina un grupo
  #
  # * DELETE /groups/1
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
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
