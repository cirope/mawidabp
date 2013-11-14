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
  # * GET /business_unit_types.xml
  def index
    @title = t 'business_unit_type.index_title'
    @business_unit_types = BusinessUnitType.order(
      ['external ASC', 'name ASC']
    ).paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @business_unit_types }
    end
  end

  # Muestra el detalle de un tipo de unidad de negocio
  # 
  # * GET /business_unit_types/1
  # * GET /business_unit_types/1.xml
  def show
    @title = t 'business_unit_type.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @business_unit_type }
    end
  end

  # Permite ingresar los datos para crear un nuevo tipo de unidad de negocio
  # 
  # * GET /business_unit_types/new
  # * GET /business_unit_types/new.xml
  def new
    @title = t 'business_unit_type.new_title'
    @business_unit_type = BusinessUnitType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @business_unit_type }
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
  # * POST /business_unit_types.xml
  def create
    @title = t 'business_unit_type.new_title'
    @business_unit_type = BusinessUnitType.new(business_unit_type_params)

    respond_to do |format|
      if @business_unit_type.save
        flash.notice = t 'business_unit_type.correctly_created'
        format.html { redirect_to(business_unit_types_url) }
        format.xml  { render :xml => @business_unit_type, :status => :created, :location => @business_unit_type }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @business_unit_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un tipo de unidad de negocio siempre que cumpla
  # con las validaciones. Además actualiza el contenido de las unidades de
  # negocio que la componen.
  # 
  # * PATCH /business_unit_types/1
  # * PATCH /business_unit_types/1.xml
  def update
    @title = t 'business_unit_type.edit_title'

    respond_to do |format|
      if @business_unit_type.update(business_unit_type_params)
        flash.notice = t 'business_unit_type.correctly_updated'
        format.html { redirect_to(business_unit_types_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @business_unit_type.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'business_unit_type.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina el tipo de unidad de negocio
  #
  # * DELETE /business_unit_types/1
  # * DELETE /business_unit_types/1.xml
  def destroy
    unless @business_unit_type.destroy
      flash.alert = t 'business_unit_type.errors.can_not_be_destroyed'
    end

    respond_to do |format|
      format.html { redirect_to(business_unit_types_url) }
      format.xml  { head :ok }
    end
  end

  private
    def set_business_unit_type
      @business_unit_type = BusinessUnitType.find(params[:id])
    end

    def business_unit_type_params
      params.require(:business_unit_type).permit(
        :name, :business_unit_label, :project_label, :external, :lock_version,
        business_units_attributes: [:id, :name, :_destroy]
      )
    end
end
