class WeaknessesController < ApplicationController
  include AutoCompleteFor::ControlObjectiveItem
  include AutoCompleteFor::FindingRelation
  include AutoCompleteFor::Tagging
  include AutoCompleteFor::WeaknessTemplate
  include Reports::CSVResponder

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_weakness, only: [
    :show, :edit, :update, :undo_reiteration
  ]
  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # Lista las observaciones
  #
  # * GET /weaknesses
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
      :work_papers, :tags,
      control_objective_item: {
        review: [:period, :plan_item, :conclusion_final_review]
      }
    ).where(@conditions, parameters).order(
      @order_by || [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} DESC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn('review_code')} ASC"
      ].map { |o| Arel.sql o }
    ).references(:periods, :conclusion_reviews)

    respond_to do |format|
      format.html { @weaknesses = @weaknesses.page params[:page] }
      format.csv  { render_or_send_by_mail @weaknesses, @title.downcase }
    end
  end

  # Muestra el detalle de una observación
  #
  # * GET /weaknesses/1
  def show
    @title = t 'weakness.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.json # show.json.jbuilder
    end
  end

  # Permite ingresar los datos para crear una nueva observación
  #
  # * GET /weaknesses/new
  def new
    @title = t 'weakness.new_title'
    @weakness = Weakness.new(
      control_objective_item_id: params[:control_objective_item]
    )

    @weakness.import_users

    respond_to do |format|
      format.html # new.html.erb
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
  def create
    @title = t 'weakness.new_title'
    @weakness = Weakness.list.new(weakness_params)

    respond_to do |format|
      if @weakness.save
        flash.notice = t 'weakness.correctly_created'
        format.html { redirect_to(edit_weakness_url(@weakness)) }
      else
        format.html { render action: :new }
      end
    end
  end

  # Actualiza el contenido de una observación siempre que cumpla con las
  # validaciones.
  #
  # * PATCH /weaknesses/1
  def update
    @title = t 'weakness.edit_title'

    respond_to do |format|
      Weakness.transaction do
        if @weakness.update(weakness_params)
          flash.notice = t 'weakness.correctly_updated'
          format.html { redirect_to(edit_weakness_url(@weakness)) }
        else
          format.html { render action: :edit }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'weakness.stale_object_error'
    redirect_to action: :edit
  end

  # Deshace la reiteración de la observación
  #
  # * PATCH /weaknesses/undo_reiteration/1
  def undo_reiteration
    @weakness.undo_reiteration

    respond_to do |format|
      format.html { redirect_to(edit_weakness_url(@weakness)) }
    end
  end

  # * GET /weaknesses/state_changed
  def state_changed
    @state = params[:state].to_i

    respond_to do |format|
      format.js
    end
  end

  # * GET /weaknesses/weakness_template_changed
  def weakness_template_changed
    @weakness_template = WeaknessTemplate.list.find_by id: params[:id]

    respond_to do |format|
      format.js
    end
  end

  private
    def weakness_params
      params.require(:weakness).permit(
        :control_objective_item_id, :review_code, :title, :description, :answer,
        :audit_comments, :state, :progress, :origination_date, :solution_date,
        :repeated_of_id, :audit_recommendations, :effect, :risk, :priority,
        :follow_up_date, :users_for_notification, :compliance, :skip_work_paper,
        :weakness_template_id, :lock_version,
        operational_risk: [], impact: [], internal_control_components: [],
        business_unit_ids: [], tag_ids: [],
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
          :answer, :commitment_date, :user_id,
          :notify_users, :_destroy, file_model_attributes: [:file, :file_cache]
        ],
        finding_relations_attributes: [
          :id, :description, :related_finding_id, :_destroy
        ],
        tasks_attributes: [
          :id, :code, :description, :status, :due_on, :_destroy
        ],
        taggings_attributes: [
          :id, :tag_id, :_destroy
        ],
        comments_attributes: [
          :user_id, :comment
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
        auto_complete_for_tagging: :read,
        auto_complete_for_finding_relation: :read,
        auto_complete_for_control_objective_item: :read,
        auto_complete_for_weakness_template: :read,
        state_changed: :read,
        undo_reiteration: :modify
      )
    end
end
