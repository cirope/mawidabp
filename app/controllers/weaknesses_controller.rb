# =Controlador de observaciones
#
# Lista, muestra, crea, modifica y elimina observaciones (#Weakness)
class WeaknessesController < ApplicationController
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
    default_conditions = [
      "#{Period.table_name}.organization_id = :organization_id",
    ]
    parameters = {
      organization_id: current_organization.id,
      boolean_true: true,
      boolean_false: false
    }

    if params[:control_objective].to_i > 0
      default_conditions << "#{Weakness.table_name}.control_objective_item_id = " +
        ":control_objective_id"
      parameters[:control_objective_id] = params[:control_objective].to_i
    end

    if params[:ids]
      default_conditions << "#{Weakness.table_name}.id IN (:ids)"
      parameters[:ids] = params[:ids].map(&:to_i)
    else
      default_conditions << [
        [
          "#{ConclusionReview.table_name}.review_id IS NULL",
          "#{Weakness.table_name}.final = :boolean_false"
        ].join(' AND '),
        [
          "#{ConclusionReview.table_name}.review_id IS NOT NULL",
          "#{Weakness.table_name}.final = :boolean_true"
        ].join(' AND ')
      ].map { |condition| "(#{condition})" }.join(' OR ')
    end

    build_search_conditions Weakness,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @weaknesses = Weakness.includes(
      :work_papers,
      control_objective_item: {
        review: [:period, :plan_item, :conclusion_final_review]
      }
    ).where(@conditions, parameters).order(
      @order_by || [
        "#{Review.table_name}.identification DESC",
        "#{Weakness.table_name}.review_code ASC"
      ]
    ).references(:periods, :conclusion_reviews).paginate(
      page: params[:page], per_page: APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html {
        if @weaknesses.size == 1 && !@query.blank? && !params[:page]
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
    @weakness = Weakness.new(weakness_params)

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

  # * GET /weaknesses/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      'organizations.id = :organization_id',
      "#{User.table_name}.hidden = false"
    ]
    parameters = {organization_id: current_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.function) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.user) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters[:"user_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @users = User.includes(:organizations).where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order(
      [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ]
    ).references(:organizations).limit(10)

    respond_to do |format|
      format.json { render json: @users }
    end
  end

  # * GET /weaknesses/auto_complete_for_finding_relation
  def auto_complete_for_finding_relation
    @tokens = params[:q][0..100].split(SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)
    @tokens.reject! { |t| t.blank? }
    conditions = [
      ("#{Finding.table_name}.id <> :finding_id" unless params[:finding_id].blank?),
      "#{Finding.table_name}.final = :boolean_false",
      "#{Period.table_name}.organization_id = :organization_id",
      [
        "#{ConclusionReview.table_name}.review_id IS NOT NULL",
        ("#{Review.table_name}.id = :review_id" unless params[:review_id].blank?)
      ].compact.join(' OR ')
    ].compact
    parameters = {
      boolean_false: false,
      finding_id: params[:finding_id],
      organization_id: current_organization.id,
      review_id: params[:review_id]
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{Finding.table_name}.review_code) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Finding.table_name}.description) LIKE :finding_relation_data_#{i}",
        "LOWER(#{ControlObjectiveItem.table_name}.control_objective_text) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Review.table_name}.identification) LIKE :finding_relation_data_#{i}",
      ].join(' OR ')

      parameters[:"finding_relation_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @findings = Finding.includes(
      control_objective_item: {review: [:period, :conclusion_final_review]}
    ).where(conditions.map {|c| "(#{c})"}.join(' AND '), parameters).order(
      [
        "#{Review.table_name}.identification ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    ).references(:control_objective_items, :reviews, :periods).limit(5)

    respond_to do |format|
      format.json { render json: @findings }
    end
  end

  # * GET /weaknesses/auto_complete_for_control_objective_item
  def auto_complete_for_control_objective_item
    @tokens = params[:q][0..100].split(SEARCH_AND_REGEXP).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Period.table_name}.organization_id = :organization_id",
      "#{ConclusionReview.table_name}.review_id IS NULL",
      "#{ControlObjectiveItem.table_name}.review_id = :review_id"
    ]
    parameters = {
      organization_id: current_organization.id,
      review_id: params[:review_id].to_i
    }

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{ControlObjectiveItem.table_name}.control_objective_text) LIKE :control_objective_item_data_#{i}"
      ].join(' OR ')

      parameters[:"control_objective_item_data_#{i}"] =
        "%#{Unicode::downcase(t)}%"
    end

    @control_objective_items = ControlObjectiveItem.includes(
      review: [:period, :conclusion_final_review]
    ).where(
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order("#{Review.table_name}.identification ASC").references(
      :periods, :conclusion_reviews, :control_objective_items
    ).limit(10)

    respond_to do |format|
      format.json { render json: @control_objective_items }
    end
  end

  private
    def weakness_params
      params.require(:weakness).permit(
        :control_objective_item_id, :review_code, :description, :answer,
        :cause_analysis, :cause_analysis_date, :correction, :correction_date,
        :audit_comments, :state, :origination_date, :solution_date, :repeated_of_id,
        :audit_recommendations, :effect, :risk, :priority, :follow_up_date,
        :users_for_notification, :lock_version,
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
      @weakness = Weakness.includes(
        :finding_relations, :work_papers,
        { finding_user_assignments: :user },
        { control_objective_item: { review: :period } }
      ).where(
        id: params[:id], Period.table_name => {organization_id: current_organization.id}
      ).references(:periods).first
    end

    def load_privileges #:nodoc:
      @action_privileges.update(
        follow_up_pdf: :read,
        auto_complete_for_user: :read,
        auto_complete_for_finding_relation: :read,
        auto_complete_for_control_objective_item: :read,
        undo_reiteration: :modify
      )
    end
end
