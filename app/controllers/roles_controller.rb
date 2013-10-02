# =Controlador de perfiles
#
# Lista, muestra, crea, modifica y elimina perfiles (#Role)
class RolesController < ApplicationController
  before_action :auth, :check_privileges

  # Lista los perfiles
  #
  # * GET /roles
  # * GET /roles.xml
  def index
    @title = t 'role.index_title'
    @roles = Role.list(@auth_organization.id).paginate(
      page: params[:page], per_page: APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @roles }
    end
  end

  # Muestra el detalle de un perfil
  #
  # * GET /roles/1
  # * GET /roles/1.xml
  def show
    @title = t 'role.show_title'
    @role = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @role }
    end
  end

  # Permite ingresar los datos para crear un nuevo perfil
  #
  # * GET /roles/new
  # * GET /roles/new.xml
  def new
    @title = t 'role.new_title'
    @role = Role.new(params[:role])

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @role }
    end
  end

  # Recupera los datos para modificar un perfil
  #
  # * GET /roles/1/edit
  def edit
    @title = t 'role.edit_title'
    @role = find_with_organization(params[:id])
    @role.role_type = params[:role][:role_type] if params[:role]
  end

  # Crea un nuevo perfil siempre que cumpla con las validaciones.
  #
  # * POST /roles
  # * POST /roles.xml
  def create
    @title = t 'role.new_title'
    @role = Role.new(role_params.merge(organization_id: @auth_organization.id))
    @role.inject_auth_privileges @auth_privileges

    respond_to do |format|
      if @role.save
        flash.notice = t 'role.correctly_created'
        format.html { redirect_to(roles_url) }
        format.xml  { render xml: @role, status: :created, location: @role }
      else
        format.html { render action: :new }
        format.xml  { render xml: @role.errors, status: :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un perfil siempre que cumpla con las validaciones.
  #
  # * PATCH /roles/1
  # * PATCH /roles/1.xml
  def update
    @title = t 'role.edit_title'
    @role = find_with_organization(params[:id])
    @role.inject_auth_privileges @auth_privileges

    respond_to do |format|
      if @role.update(role_params.merge(organization_id: @auth_organization.id))
        flash.notice = t 'role.correctly_updated'
        format.html { redirect_to(roles_url) }
        format.xml  { head :ok }
      else
        format.html { render action: :edit }
        format.xml  { render xml: @role.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'role.stale_object_error'
    redirect_to action: :edit
  end

  # Elimina un perfil
  #
  # * DELETE /roles/1
  # * DELETE /roles/1.xml
  def destroy
    @role = find_with_organization(params[:id])
    @role.destroy

    respond_to do |format|
      format.html { redirect_to(roles_url) }
      format.xml  { head :ok }
    end
  end

  private

  def role_params
    params.require(:role).permit(
      :name, :role_type, :lock_version, privileges_attributes: [
        :id, :module, :approval, :erase, :modify, :read
      ]
    )
  end

  # Busca el perfil indicado siempre que pertenezca a la organización. En el
  # caso que no se encuentre (ya sea que no existe un perfil con ese ID o que
  # no pertenece a la organización con la que se autenticó el usuario) devuelve
  # nil.
  # 
  # _id_::  ID del informe que se quiere recuperar
  def find_with_organization(id) #:doc:
    Role.where(id: id, organization_id: @auth_organization.id).first
  end
end
