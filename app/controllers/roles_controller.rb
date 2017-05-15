class RolesController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_role, only: [:show, :edit, :update, :destroy]

  # Lista los perfiles
  #
  # * GET /roles
  def index
    @title = t 'role.index_title'
    @roles = Role.list.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # Muestra el detalle de un perfil
  #
  # * GET /roles/1
  def show
    @title = t 'role.show_title'

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # Permite ingresar los datos para crear un nuevo perfil
  #
  # * GET /roles/new
  def new
    @title = t 'role.new_title'
    @role = Role.new params[:role] ? role_params : {}

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # Recupera los datos para modificar un perfil
  #
  # * GET /roles/1/edit
  def edit
    @title = t 'role.edit_title'
    @role.role_type = params[:role][:role_type] if params[:role]
  end

  # Crea un nuevo perfil siempre que cumpla con las validaciones.
  #
  # * POST /roles
  def create
    @title = t 'role.new_title'
    @role = Role.list.new(role_params)
    @role.inject_auth_privileges @auth_privileges

    respond_to do |format|
      if @role.save
        flash.notice = t 'role.correctly_created'
        format.html { redirect_to(roles_url) }
      else
        format.html { render action: :new }
      end
    end
  end

  # Actualiza el contenido de un perfil siempre que cumpla con las validaciones.
  #
  # * PATCH /roles/1
  def update
    @title = t 'role.edit_title'
    @role.inject_auth_privileges @auth_privileges

    respond_to do |format|
      if @role.update(role_params)
        flash.notice = t 'role.correctly_updated'
        format.html { redirect_to(roles_url) }
      else
        format.html { render action: :edit }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'role.stale_object_error'
    redirect_to action: :edit
  end

  # Elimina un perfil
  #
  # * DELETE /roles/1
  def destroy
    @role.destroy

    respond_to do |format|
      format.html { redirect_to(roles_url) }
    end
  end

  private
    def set_role
      @role = Role.list.find(params[:id])
    end

    def role_params
      params.require(:role).permit(
        :name, :role_type, :lock_version, privileges_attributes: [
          :id, :module, :approval, :erase, :modify, :read
        ]
      )
    end
end
