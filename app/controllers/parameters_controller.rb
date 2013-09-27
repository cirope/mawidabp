# =Controlador de parámetros
#
# Lista, muestra, modifica y elimina parámetros (#Parameter)
class ParametersController < ApplicationController
  before_action :auth, :check_privileges
  hide_action :form_keys_to_array, :clean_parameters, :find_with_organization

  # Lista los parámetros
  #
  # * GET /parameters
  # * GET /parameters.xml
  def index
    @title = t 'parameter.index_title'
    @type = APP_PARAMETER_TYPES.include?(params[:type]) ? params[:type] : :admin
    @parameters = Parameter.where(
      [
        [
          'name LIKE :name',
          'organization_id = :organization_id'
        ].join(' AND '),
        {
          :name => "#{@type}_%",
          :organization_id => @auth_organization.id
        }
      ]
    ).order('name ASC').paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @parameters }
    end
  end

  # Muestra el detalle de un parámetro
  #
  # * GET /parameters/1
  # * GET /parameters/1.xml
  def show
    @title = t 'parameter.show_title'
    @parameter = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @parameter }
    end
  end

  # Recupera los datos para modificar un parámetro
  #
  # * GET /parameters/1/edit
  def edit
    @title = t 'parameter.edit_title'
    @type = params[:type]
    @parameter = find_with_organization(params[:id])
  end

  # Actualiza el contenido de un parámetro siempre que cumpla con las
  # validaciones.
  #
  # * PATCH /parameters/1
  # * PATCH /parameters/1.xml
  def update
    @title = t 'parameter.edit_title'
    @type = APP_PARAMETER_TYPES.include?(params[:type]) ? params[:type] : :admin
    @parameter = find_with_organization(params[:id])

    unless params[:parameter][:value]
      params[:parameter][:value] = form_keys_to_array(params[:parameter])
    end

    respond_to do |format|
      if @parameter.update(clean_parameters(params[:parameter]))
        flash.notice = t 'parameter.correctly_updated'
        format.html { redirect_to(parameters_url(:type => @type)) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @parameter.errors, :status => :unprocessable_entity }
      end
    end
    
  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'parameter.stale_object_error'
    redirect_to :action => :edit
  end

  private
    # Recorre todos los atributos  que vienen como llave_número => valor y los
    # convierte en [[atributo, valor], ....]
    def form_keys_to_array(parameters) #:doc:
      result = []

      parameters.each do |key, value|
        result << [value, parameters["value_#{$1}"]] if key =~ /\Akey_(.*)\Z/
      end

      result.sort { |item_1, item_2| item_1[1] <=> item_2[1] }
    end

    # Elimina los atributos que comienzan con key_ o value_ para que puedan ser
    # utilizados directamente en los métodos new, update, etc.
    def clean_parameters(parameters) #:doc:
      parameters.reject { |k,| k =~ /\Akey_.*\Z|\Avalue_.*\Z/ }
    end

    # Busca el parámetro indicado siempre que pertenezca a la organización. En el
    # caso que no se encuentre (ya sea que no existe un parámetro con ese ID o que
    # no pertenece a la organización con la que se autenticó el usuario) devuelve
    # nil.
    # _id_::  ID del parámetro que se quiere recuperar
    def find_with_organization(id) #:doc:
      Parameter.where(
        :id => id, :organization_id => @auth_organization.id
      ).first
    end
end
