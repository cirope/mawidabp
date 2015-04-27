class WeaknessesController < ApplicationController
  include AutoCompleteFor::FindingRelation
  include AutoCompleteFor::ControlObjectiveItem

  before_filter :auth, :load_privileges, :check_privileges
  before_action :set_weakness, only: [
    :show, :edit, :update, :follow_up_pdf, :undo_reiteration
  ]
  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # Lista las observaciones
  #
  # * GET /weaknesses
  # * GET /weaknesses.xml
  def index
    @title = t 'weakness.index_title'
    default_conditions = []
    parameters = { boolean_true: true, boolean_false: false }

    if params[:control_objective].to_i > 0
      default_conditions << "#{Weakness.quoted_table_name}.#{Weakness.qcn('control_objective_item_id')} = " +
        ":control_objective_id"
      parameters[:control_objective_id] = params[:control_objective].to_i
    end

    if params[:ids]
      default_conditions << "#{Weakness.quoted_table_name}.#{Weakness.qcn('id')} IN (:ids)"
      parameters[:ids] = params[:ids].map(&:to_i)
    else
      default_conditions <<
      [
        [
          "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NULL",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn('final')} = :boolean_false"
        ].join(' AND '),
        [
          "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn('final')} = :boolean_true"
        ].join(' AND ')
      ].map { |condition| "(#{condition})" }.join(' OR ')
    end

    build_search_conditions Weakness,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @weaknesses = Weakness.list.includes(
      :work_papers,
      control_objective_item: {
        review: [:period, :plan_item, :conclusion_final_review]
      }
    ).where(@conditions, parameters).order(
      @order_by || [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} DESC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn('review_code')} ASC"
      ]
    ).references(:periods, :conclusion_reviews).page(params[:page])

    respond_to do |format|
      format.html {
        if @weaknesses.count == 1 && !@query.blank? && !params[:page]
          redirect_to weakness_url(@weaknesses.first)
        end
      } # index.html.erb
      format.xml  { render xml: @weaknesses }
    end
  end

  # Muestra el detalle de una observación
  #
  # * GET /weaknesses/1
  # * GET /weaknesses/1.xml
  def show
    @title = t 'weakness.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.json # show.json.jbuilder
      format.xml  { render xml: @weakness }
    end
  end

  # Permite ingresar los datos para crear una nueva observación
  #
  # * GET /weaknesses/new
  # * GET /weaknesses/new.xml
  def new
    @title = t 'weakness.new_title'
    @weakness = Weakness.new(
      {control_objective_item_id: params[:control_objective_item]}, {}, true
    )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @weakness }
    end
  end

  # Recupera los datos para modificar una observación
  #
  # * GET /weaknesses/1/edit
  def edit
    @title = t 'weakness.edit_title'
  end

  # Crea una observación siempre que cumpla con las validaciones.
  #
  # * POST /weaknesses
  # * POST /weaknesses.xml
  def create
    @title = t 'weakness.new_title'
    @weakness = Weakness.list.new(weakness_params)

    respond_to do |format|
      if @weakness.save
        flash.notice = t 'weakness.correctly_created'
        format.html { redirect_to(edit_weakness_url(@weakness)) }
        format.xml  { render xml: @weakness, status: :created, location: @weakness }
      else
        format.html { render action: :new }
        format.xml  { render xml: @weakness.errors, status: :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de una observación siempre que cumpla con las
  # validaciones.
  #
  # * PATCH /weaknesses/1
  # * PATCH /weaknesses/1.xml
  def update
    @title = t 'weakness.edit_title'

    respond_to do |format|
      Weakness.transaction do
        if @weakness.update(weakness_params)
          flash.notice = t 'weakness.correctly_updated'
          format.html { redirect_to(edit_weakness_url(@weakness)) }
          format.xml  { head :ok }
        else
          format.html { render action: :edit }
          format.xml  { render xml: @weakness.errors, status: :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'weakness.stale_object_error'
    redirect_to action: :edit
  end

  # Crea el documento de seguimiento de la observación
  #
  # * GET /weaknesses/follow_up_pdf/1
  def follow_up_pdf
    @weakness.follow_up_pdf(current_organization)
    redirect_to @weakness.relative_follow_up_pdf_path
  end

  # Deshace la reiteración de la observación
  #
  # * PATCH /weaknesses/undo_reiteration/1
  def undo_reiteration
    @weakness.undo_reiteration

    respond_to do |format|
      format.html { redirect_to(edit_weakness_url(@weakness)) }
      format.xml  { head :ok }
    end
  end

  private
    def weakness_params
      params.require(:weakness).permit(
        :control_objective_item_id, :review_code, :title, :description, :answer,
        :cause_analysis, :cause_analysis_date, :correction, :correction_date,
        :audit_comments, :state, :origination_date, :solution_date, :repeated_of_id,
        :audit_recommendations, :effect, :risk, :priority, :follow_up_date,
        :users_for_notification, :lock_version,
        business_unit_ids: [],
        achievements_attributes: [
          :id, :benefit_id, :amount, :comment, :_destroy
        ],
        finding_user_assignments_attributes: [
          :id, :user_id, :process_owner, :responsible_auditor, :_destroy
        ],
        work_papers_attributes: [
          :id, :name, :code, :number_of_pages, :description, :_destroy,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_answers_attributes: [
          :id, :answer, :auditor_comments, :commitment_date, :user_id,
          :notify_users, :_destroy, file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_relations_attributes: [
          :id, :description, :related_finding_id, :_destroy
        ]
      )
    end

    def set_weakness
      @weakness = Weakness.list.includes(
        :finding_relations, :work_papers,
        { finding_user_assignments: :user },
        { control_objective_item: { review: :period } }
      ).find(params[:id])
    end

    def load_privileges
      @action_privileges.update(
        follow_up_pdf: :read,
        auto_complete_for_finding_relation: :read,
        auto_complete_for_control_objective_item: :read,
        undo_reiteration: :modify
      )
    end
end
