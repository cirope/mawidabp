class WorkflowsController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges
  before_action :set_workflow, only: [
    :show, :edit, :update, :destroy, :export_to_pdf
  ]
  before_action :set_workflow_clone, only: [:new]
  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # Lista los programas de trabajo
  #
  # * GET /workflows
  # * GET /workflows.xml
  def index
    @title = t 'workflow.index_title'
    @workflows = Workflow.list.includes(:review).order(
      "#{Review.table_name}.identification DESC").page(
      params[:page]
    ).references(:reviews)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @workflows }
    end
  end

  # Muestra el detalle de un programa de trabajo
  #
  # * GET /workflows/1
  # * GET /workflows/1.xml
  def show
    @title = t 'workflow.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @workflow }
    end
  end

  # Permite ingresar los datos para crear un programa de trabajo
  #
  # * GET /workflows/new
  # * GET /workflows/new.xml
  def new
    @title = t 'workflow.new_title'
    @workflow = Workflow.new

    if @workflow_clone
      @workflow_clone.workflow_items.each do |wi|
        attributes = wi.attributes.merge(
          'id' => nil,
          'resource_utilizations_attributes' =>
            wi.resource_utilizations.map { |ru| ru.attributes.merge 'id' => nil }
        )

        @workflow.workflow_items.build(attributes)
      end
    else
      @workflow.workflow_items.build
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @workflow }
    end
  end

  # Recupera los datos para modificar un programa de trabajo
  #
  # * GET /workflows/1/edit
  def edit
    @title = t 'workflow.edit_title'
  end

  # Crea un nuevo programa de trabajo siempre que cumpla con las validaciones.
  # Además crea los ítems que lo componen.
  #
  # * POST /workflows
  # * POST /workflows.xml
  def create
    @title = t 'workflow.new_title'
    @workflow = Workflow.list.new(workflow_params)
    @workflow.workflow_items.sort! do |wfi_a, wfi_b|
      wfi_a.order_number.to_i <=> wfi_b.order_number.to_i
    end

    respond_to do |format|
      if @workflow.save
        flash.notice = t 'workflow.correctly_created'
        format.html { redirect_to(workflows_url) }
        format.xml  { render xml: @workflow, status: :created, location: @workflow }
      else
        format.html { render action: :new }
        format.xml  { render xml: @workflow.errors, status: :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un programa de trabajo (o crea una nueva versión
  # del mismo) siempre que cumpla con las validaciones. Además actualiza el
  # contenido de los ítems que lo componen.
  #
  # * PATCH /workflows/1
  # * PATCH /workflows/1.xml
  def update
    @title = t 'workflow.edit_title'
    @workflow.workflow_items.sort! do |wfi_a, wfi_b|
      wfi_a.order_number <=> wfi_b.order_number
    end

    respond_to do |format|
      if @workflow.update(workflow_params)
        flash.notice = t 'workflow.correctly_updated'
        format.html { redirect_to(workflows_url) }
        format.xml  { head :ok }
      else
        format.html { render action: :edit }
        format.xml  { render xml: @workflow.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'workflow.stale_object_error'
    redirect_to action: :edit
  end

  # Elimina un programa de trabajo
  #
  # * DELETE /workflows/1
  # * DELETE /workflows/1.xml
  def destroy
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to(workflows_url) }
      format.xml  { head :ok }
    end
  end

  # Exporta el programa de trabajo en formato PDF
  #
  # * GET /workflow_items/export_to_pdf/1
  def export_to_pdf
    @workflow.to_pdf current_organization, !params[:include_details].blank?

    respond_to do |format|
      format.html { redirect_to @workflow.relative_pdf_path }
      format.xml  { head :ok }
    end
  end

  # * POST /workflows/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Organization.table_name}.id = :organization_id",
      "#{User.table_name}.hidden = false"
    ]
    parameters = {organization_id: current_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{Resource.table_name}.name) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters["user_data_#{i}".to_sym] = "%#{Unicode::downcase(t)}%"
    end

    @users = User.includes(:organizations, :resource).where(
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order(
      ["#{User.table_name}.last_name ASC", "#{User.table_name}.name ASC"]
    ).references(:organizations).limit(10)

    respond_to do |format|
      format.json {
        render json: @users.to_json(
          methods: [:label, :informal, :cost_per_unit]
        )
      }
    end
  end

  # Lista los informes del periodo indicado, devuelve un Hash en JSON
  #
  # * GET /reviews/reviews_for_period/?period=id
  def reviews_for_period
    options = [[t('helpers.select.prompt'), '']]
    reviews = Review.list_without_final_review.list_all_without_workflow(
      params[:period])

    reviews.each { |r| options << [r.identification, r.id] }

    render json: options
  end

  # * GET /workflows/resource_data/1
  def resource_data
    resource = Resource.find(params[:id])

    render json: resource.to_json(only: :cost_per_unit)
  end

  # * GET /workflows/estimated_amount/1
  def estimated_amount
    review = Review.find(params[:id]) unless params[:id].blank?

    render partial: 'estimated_amount',
      locals: {plan_item: review.try(:plan_item)}
  end

  private
    def workflow_params
      params.require(:workflow).permit(
        :period_id, :review_id, :allow_overload, :lock_version,
        workflow_items_attributes: [
          :id, :task, :start, :end, :plain_predecessors, :order_number, :_destroy,
          resource_utilizations_attributes: [
            :id, :resource_id, :resource_type, :units, :cost_per_unit, :_destroy
          ]
        ]
      )
    end

    def set_workflow
      @workflow = Workflow.list.includes(
        { workflow_items: :resource_utilizations }
      ).find(params[:id])
    end

    def set_workflow_clone
      @workflow_clone = Workflow.list.find_by(
        id: params[:clone_from].try(:to_i)
      )
    end

    def load_privileges
      @action_privileges.update(
        export_to_pdf: :read,
        auto_complete_for_user: :read,
        reviews_for_period: :read,
        resource_data: :read,
        estimated_amount: :read
      )
    end
end
