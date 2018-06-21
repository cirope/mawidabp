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
  def index
    @title = t 'workflow.index_title'
    @workflows = Workflow.list.includes(:review).order(
      Arel.sql "#{Review.quoted_table_name}.#{Review.qcn('identification')} DESC"
    ).page(
      params[:page]
    ).references(:reviews)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # Muestra el detalle de un programa de trabajo
  #
  # * GET /workflows/1
  def show
    @title = t 'workflow.show_title'

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # Permite ingresar los datos para crear un programa de trabajo
  #
  # * GET /workflows/new
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
  def create
    @title = t 'workflow.new_title'
    @workflow = Workflow.list.new(workflow_params)

    respond_to do |format|
      if @workflow.save
        flash.notice = t 'workflow.correctly_created'
        format.html { redirect_to(workflows_url) }
      else
        format.html { render action: :new }
      end
    end
  end

  # Actualiza el contenido de un programa de trabajo (o crea una nueva versión
  # del mismo) siempre que cumpla con las validaciones. Además actualiza el
  # contenido de los ítems que lo componen.
  #
  # * PATCH /workflows/1
  def update
    @title = t 'workflow.edit_title'

    respond_to do |format|
      if @workflow.update(workflow_params)
        flash.notice = t 'workflow.correctly_updated'
        format.html { redirect_to(workflows_url) }
      else
        format.html { render action: :edit }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'workflow.stale_object_error'
    redirect_to action: :edit
  end

  # Elimina un programa de trabajo
  #
  # * DELETE /workflows/1
  def destroy
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to(workflows_url) }
    end
  end

  # Exporta el programa de trabajo en formato PDF
  #
  # * GET /workflow_items/export_to_pdf/1
  def export_to_pdf
    @workflow.to_pdf current_organization, !params[:include_details].blank?

    respond_to do |format|
      format.html { redirect_to @workflow.relative_pdf_path }
    end
  end

  # Lista los informes del periodo indicado, devuelve un Hash en JSON
  #
  # * GET /reviews/reviews_for_period/?period=id
  def reviews_for_period
    options = [[t('helpers.select.prompt'), '']]
    reviews = Review.list_without_final_review_or_not_closed.list_all_without_workflow(params[:period])

    reviews.each { |r| options << [r.identification, r.id] }

    render json: options
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
          :id, :task, :start, :end, :order_number, :_destroy,
          resource_utilizations_attributes: [
            :id, :resource_id, :resource_type, :units, :_destroy
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
        reviews_for_period: :read,
        estimated_amount: :read
      )
    end
end
