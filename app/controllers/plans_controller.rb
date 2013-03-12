# encoding: utf-8
# =Controlador de planes de trabajo
#
# Lista, muestra, crea, modifica y elimina planes de trabajo (#Plan) y sus ítems
# (#PlanItem)
class PlansController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges,
    :find_business_unit_type
  layout proc { |controller| controller.request.xhr? ? false : 'application' }
  hide_action :find_with_organization, :update_auth_user_id, :exists?,
    :load_privileges

  # Lista los planes de trabajo
  #
  # * GET /plans
  # * GET /plans.xml
  def index
    @title = t 'plan.index_title'
    @plans = Plan.includes(:period).where(
      "#{Period.table_name}.organization_id" => @auth_organization.id
    ).order("#{Period.table_name}.start DESC").paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @plans }
    end
  end

  # Muestra el detalle de un plan de trabajo
  #
  # * GET /plans/1
  # * GET /plans/1.xml
  def show
    @title = t 'plan.show_title'
    @plan = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @plan }
    end
  end

  # Permite ingresar los datos para crear un plan de trabajo
  #
  # * GET /plans/new
  # * GET /plans/new.xml
  def new
    @title = t 'plan.new_title'
    @plan = Plan.new
    clone_id = params[:clone_from].to_i
    clone_plan = find_with_organization(clone_id) if exists?(clone_id)

    @plan.clone_from clone_plan if clone_plan

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @plan }
    end
  end

  # Recupera los datos para modificar un plan de trabajo
  #
  # * GET /plans/1/edit
  def edit
    @title = t 'plan.edit_title'
    @plan = find_with_organization(params[:id], true)
  end

  # Crea un nuevo plan de trabajo siempre que cumpla con las validaciones.
  # Además crea los ítems que lo componen.
  #
  # * POST /plans
  # * POST /plans.xml
  def create
    @title = t 'plan.new_title'
    @plan = Plan.new(params[:plan])
    clone_id = params[:clone_from].to_i
    clone_plan = find_with_organization(clone_id) if exists?(clone_id)

    @plan.clone_from clone_plan if clone_plan

    respond_to do |format|
      if @plan.save
        format.html { redirect_to(edit_plan_url(@plan, :business_unit_type => params[:business_unit_type]), :notice => t('plan.correctly_created')) }
        format.xml  { render :xml => @plan, :status => :created, :location => @plan }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @plan.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un plan de trabajo (o crea una nueva versión del
  # mismo) siempre que cumpla con las validaciones. Además actualiza el
  # contenido de los ítems que lo componen.
  #
  # * PUT /plans/1
  # * PUT /plans/1.xml
  def update
    @title = t 'plan.edit_title'
    @plan = find_with_organization(params[:id], true)

    respond_to do |format|
      if @plan.update_attributes(params[:plan])
        format.html { redirect_to(edit_plan_url(@plan, :business_unit_type => params[:business_unit_type]), :notice => t('plan.correctly_updated')) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @plan.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'plan.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina un plan de trabajo
  #
  # * DELETE /plans/1
  # * DELETE /plans/1.xml
  def destroy
    @plan = find_with_organization(params[:id])

    unless @plan.destroy
      flash.alert = t 'plan.errors.can_not_be_destroyed'
    end

    respond_to do |format|
      format.html { redirect_to(plans_url) }
      format.xml  { head :ok }
    end
  end

  # Exporta el plan de trabajo en formato PDF
  #
  # * GET /plans/export_to_pdf/1
  def export_to_pdf
    @plan = find_with_organization(params[:id], true)
    @plan.to_pdf @auth_organization, !params[:include_details].blank?

    respond_to do |format|
      format.html { redirect_to @plan.relative_pdf_path }
      format.xml  { head :ok }
    end
  end

  # * GET /plans/auto_complete_for_business_unit_business_unit_id
  def auto_complete_for_business_unit_business_unit_id
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{BusinessUnitType.table_name}.organization_id = :organization_id"
    ]
    parameters = {:organization_id => @auth_organization.id}

    if params[:business_unit_type_id].to_i > 0
      conditions << "#{BusinessUnitType.table_name}.id = :but_id"
      parameters[:but_id] = params[:business_unit_type_id].to_i
    end

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{BusinessUnit.table_name}.name) LIKE :business_unit_data_#{i}"
      ].join(' OR ')

      parameters[:"business_unit_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @business_units = BusinessUnit.includes(:business_unit_type).where(
      [conditions.map {|c| "(#{c})"}.join(' AND '), parameters]
    ).order(
      [
        "#{BusinessUnit.table_name}.name ASC",
        "#{BusinessUnitType.table_name}.name ASC"
      ]
    ).limit(10)

    respond_to do |format|
      format.json { render :json => @business_units }
    end
  end

  # * GET /plans/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Organization.table_name}.id = :organization_id",
      "#{User.table_name}.hidden = false"
    ]
    parameters = {:organization_id => @auth_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{Resource.table_name}.name) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters[:"user_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @users = User.includes(:organizations, :resource).where(
      [conditions.map {|c| "(#{c})"}.join(' AND '), parameters]
    ).order(
      ["#{User.table_name}.last_name ASC", "#{User.table_name}.name ASC"]
    ).limit(10)

    respond_to do |format|
      format.json {
        render :json => @users.to_json(
          :methods => [:label, :informal, :cost_per_unit]
        )
      }
    end
  end

  # * GET /plans/resource_data/1
  def resource_data
    resource = Resource.find(params[:id])

    render :json => resource.to_json(:only => :cost_per_unit)
  end

  private

  def find_business_unit_type
    if params[:business_unit_type].to_i > 0
      @business_unit_type = BusinessUnitType.find params[:business_unit_type].to_i
    end
  end

  # Busca el plan de trabajo indicado siempre que pertenezca a la organización.
  # En el caso que no se encuentre (ya sea que no existe un plan de trabajo con
  # ese ID o que no pertenece a la organización con la que se autenticó el
  # usuario) devuelve nil.
  # _id_::  ID del plan de trabajo que se quiere recuperar
  def find_with_organization(id, include_all = false) #:doc:
    include = include_all ? [
      :period, {
        :plan_items => [
          :resource_utilizations,
          :business_unit,
          {:review => :conclusion_final_review}
        ]
      }
    ] : [:period]

    Plan.includes(*include).where(
      :id => id, "#{Period.table_name}.organization_id" => @auth_organization.id
    ).first(:readonly => false)
  end

  # Indica si existe el plan de trabajo indicado, siempre que pertenezca a la
  # organización. En el caso que no se encuentre (ya sea que no existe un plan
  # de trabajo con ese ID o que no pertenece a la organización con la que se
  # autenticó el usuario) devuelve false.
  # _id_::  ID del plan de trabajo que se quiere recuperar
  def exists?(id) #:doc:
    Plan.includes(:period).where(
      :id => id, "#{Period.table_name}.organization_id" => @auth_organization.id
    ).first
  end

  def load_privileges #:nodoc:
    @action_privileges.update(
      :export_to_pdf => :read,
      :auto_complete_for_business_unit_business_unit_id => :read,
      :auto_complete_for_user => :read,
      :resource_data => :read
    )
  end
end
