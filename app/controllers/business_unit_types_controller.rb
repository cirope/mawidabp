# =Controlador de tipos de unidades de negocio
#
# Lista, muestra, crea, modifica y elimina tipos de unidades de negocio
# (#BusinessUnitType) y unidades de negocio (#BusinessUnit)
class BusinessUnitTypesController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_business_unit_type, only: [:show, :edit, :update, :destroy]

  # Lista los tipos de unidades de negocio
  #
  # * GET /business_unit_types
  def index
    @title = t 'business_unit_type.index_title'
    @business_unit_types = BusinessUnitType.list.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # Muestra el detalle de un tipo de unidad de negocio
  #
  # * GET /business_unit_types/1
  def show
    @title = t 'business_unit_type.show_title'

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # Permite ingresar los datos para crear un nuevo tipo de unidad de negocio
  #
  # * GET /business_unit_types/new
  def new
    @title = t 'business_unit_type.new_title'
    @business_unit_type = BusinessUnitType.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # Recupera los datos para modificar un tipo de unidad de negocio
  #
  # * GET /business_unit_types/1/edit
  def edit
    @title = t 'business_unit_type.edit_title'
  end

  # Crea un nuevo tipo de unidad de negocio siempre que cumpla con las
  # validaciones. Además crea las unidades de negocio que lo componen.
  #
  # * POST /business_unit_types
  def create
    @title = t 'business_unit_type.new_title'
    @business_unit_type = BusinessUnitType.list.new(business_unit_type_params)

    respond_to do |format|
      if @business_unit_type.save
        flash.notice = t 'business_unit_type.correctly_created'
        format.html { redirect_to(business_unit_types_url) }
      else
        format.html { render :action => :new }
      end
    end
  end

  # Actualiza el contenido de un tipo de unidad de negocio siempre que cumpla
  # con las validaciones. Además actualiza el contenido de las unidades de
  # negocio que la componen.
  #
  # * PATCH /business_unit_types/1
  def update
    @title = t 'business_unit_type.edit_title'

    respond_to do |format|
      if @business_unit_type.update(business_unit_type_params)
        flash.notice = t 'business_unit_type.correctly_updated'
        format.html { redirect_to(business_unit_types_url) }
      else
        format.html { render :action => :edit }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'business_unit_type.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina el tipo de unidad de negocio
  #
  # * DELETE /business_unit_types/1
  def destroy
    unless @business_unit_type.destroy
      flash.alert = t 'business_unit_type.errors.can_not_be_destroyed'
    end

    respond_to do |format|
      format.html { redirect_to(business_unit_types_url) }
    end
  end

  private
    def set_business_unit_type
      @business_unit_type = BusinessUnitType.list.find(params[:id])
    end

    def business_unit_type_params
      params.require(:business_unit_type).permit(
        :name, :business_unit_label, :project_label, :external, :lock_version,
        business_units_attributes: [:id, :name, :_destroy]
      )
    end
end
