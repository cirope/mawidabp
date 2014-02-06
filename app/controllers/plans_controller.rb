class PlansController < ApplicationController
  include AutoCompleteFor::User

  before_action :auth, :load_privileges, :check_privileges,
    :find_business_unit_type
  before_action :set_plan, only: [
    :show, :edit, :update, :destroy, :export_to_pdf
  ]
  before_action :set_plan_clone, only: [:new, :create]
  layout proc { |controller| controller.request.xhr? ? false : 'application' }

  # Lista los planes de trabajo
  #
  # * GET /plans
  # * GET /plans.xml
  def index
    @title = t 'plan.index_title'
    @plans = Plan.list.includes(:period).order(
      "#{Period.table_name}.start DESC"
    ).page(params[:page])

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

    @plan.clone_from @plan_clone if @plan_clone

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
  end

  # Crea un nuevo plan de trabajo siempre que cumpla con las validaciones.
  # Además crea los ítems que lo componen.
  #
  # * POST /plans
  # * POST /plans.xml
  def create
    @title = t 'plan.new_title'
    @plan = Plan.list.new(plan_params)

    @plan.clone_from @plan_clone if @plan_clone

    respond_to do |format|
      if @plan.save
        format.html {
          redirect_to(
            edit_plan_url(@plan, business_unit_type: params[:business_unit_type]),
            notice: t('plan.correctly_created')
          )
        }
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
  # * PATCH /plans/1
  # * PATCH /plans/1.xml
  def update
    @title = t 'plan.edit_title'

    respond_to do |format|
      if @plan.update(plan_params)
        format.html {
          redirect_to(
            edit_plan_url(@plan, business_unit_type: params[:business_unit_type]),
            notice: t('plan.correctly_updated')
          )
        }
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
    @plan.to_pdf current_organization, !params[:include_details].blank?

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
    parameters = {:organization_id => current_organization.id}

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

  # * GET /plans/resource_data/1
  def resource_data
    resource = Resource.find(params[:id])

    render :json => resource.to_json(:only => :cost_per_unit)
  end

  private
    def plan_params
      params.require(:plan).permit(
        :period_id, :allow_overload, :allow_duplication, :new_version,
        :lock_version, plan_items_attributes: [
          :id, :project, :start, :end, :plain_predecessors, :order_number,
          :business_unit_id, :_destroy,
          resource_utilizations_attributes: [
            :id, :resource_id, :resource_type, :units, :cost_per_unit, :_destroy
          ]
        ]
      )
    end

    def find_business_unit_type
      if params[:business_unit_type].to_i > 0
        @business_unit_type = BusinessUnitType.find params[:business_unit_type].to_i
      end
    end

    def set_plan
      @plan = Plan.list.includes(
        plan_items: [
          :resource_utilizations, :business_unit,
          { review: :conclusion_final_review }
        ]
      ).find(params[:id])
    end

    def set_plan_clone
      @plan_clone = Plan.list.find_by(id: params[:clone_from].try(:to_i))
    end

    def load_privileges
      @action_privileges.update(
        :export_to_pdf => :read,
        :auto_complete_for_business_unit_business_unit_id => :read,
        :auto_complete_for_user => :read,
        :resource_data => :read
      )
    end
end
