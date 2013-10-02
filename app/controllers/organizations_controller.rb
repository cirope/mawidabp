# =Controlador de organizaciones
#
# Lista, muestra, crea, modifica y elimina organizaciones (#Organization) y
# unidades de negocio (#BusinessUnit)
class OrganizationsController < ApplicationController
  before_action :auth, :check_privileges
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }
  hide_action :update_auth_user_id

  # Lista las organizaciones
  #
  # * GET /organizations
  # * GET /organizations.xml
  def index
    @title = t 'organization.index_title'
    @organizations = Organization.where(
      :group_id => @auth_organization.group_id
    ).order('name ASC').paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @organizations }
    end
  end

  # Muestra el detalle de una organización
  #
  # * GET /organizations/1
  # * GET /organizations/1.xml
  def show
    @title = t 'organization.show_title'
    @organization = find_if_allowed(params[:id])

    respond_to do |format|
      format.html # show.html.erbtype
      format.xml  { render :xml => @organization }
    end
  end

  # Permite ingresar los datos para crear una nueva organización
  #
  # * GET /organizations/new
  # * GET /organizations/new.xml
  def new
    @title = t 'organization.new_title'
    @organization = Organization.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # Recupera los datos para modificar una organización
  #
  # * GET /organizations/1/edit
  def edit
    @title = t 'organization.edit_title'
    @organization = find_if_allowed(params[:id])
  end

  # Crea una nueva organización siempre que cumpla con las validaciones. Además
  # crea las unidades de negocio que la componen.
  #
  # * POST /organizations
  # * POST /organizations.xml
  def create
    @title = t 'organization.new_title'
    params[:organization].delete :business_units_attributes
    @organization = Organization.new(organization_params)
    @organization.must_create_parameters = true
    @organization.must_create_roles = true

    respond_to do |format|
      saved = false

      Organization.transaction do
        saved = @organization.save &&
          @auth_user.organization_roles.create(
            :organization => @organization,
            :role => @organization.roles.sort.first
          ).valid?
          
        raise ActiveRecord::Rollback unless saved
      end

      if saved
        flash.notice = t 'organization.correctly_created'
        format.html { redirect_to(organizations_url) }
        format.xml  { render :xml => @organization, :status => :created, :location => @organization }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de una organización siempre que cumpla con las
  # validaciones. Además actualiza el contenido de las unidades de negocio que
  # la componen.
  #
  # * PATCH /organizations/1
  # * PATCH /organizations/1.xml
  def update
    @title = t 'organization.edit_title'
    @organization = find_if_allowed(params[:id])
    params[:organization].delete :business_units_attributes

    respond_to do |format|
      if @organization.update(organization_params)
        flash.notice = t 'organization.correctly_updated'
        format.html { redirect_to(organizations_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
    
  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'organization.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina una organización
  #
  # * DELETE /organizations/1
  # * DELETE /organizations/1.xml
  def destroy
    @organization = find_if_allowed(params[:id])
    @organization.destroy

    respond_to do |format|
      format.html { redirect_to(organizations_url) }
      format.xml  { head :ok }
    end
  end

  private

  def organization_params
    params.require(:organization).permit(
      :name, :prefix, :description, :group_id, :image_model_id
    )
  end
  # Busca una organización sólo si está dentro de las que el usuario tiene
  # permitidas ver, si es así y existe la devuelve, caso contrario retorna nil
  #
  # _id_::  ID de la organización que se quiere buscar
  def find_if_allowed(id) #:doc:
    Organization.where(:group_id => @auth_organization.group_id, :id => id).first
  end
end
