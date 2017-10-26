class ReviewsController < ApplicationController
  include AutoCompleteFor::ProcessControl
  include AutoCompleteFor::Tagging
  include SearchableByTag

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_review, only: [
    :show, :edit, :update, :destroy, :review_data, :download_work_papers,
    :survey_pdf, :recode_findings, :recode_findings_by_risk
  ]
  before_action :set_review_clone, only: [:new]
  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # Lista los informes
  #
  # * GET /reviews
  def index
    @title = t 'review.index_title'
    scope  = Review.list.
      includes(:conclusion_final_review, :period, :tags, {
        plan_item: :business_unit
      }).
      references(:periods)

    tagged_reviews = build_tag_search_for scope

    build_search_conditions Review

    reviews = @columns == ['tags'] ? scope.none : scope.where(@conditions)
    order = @order_by || Review.default_order

    @reviews = tagged_reviews.
      or(reviews).
      reorder(order).
      page(params[:page])

    respond_to do |format|
      format.html
    end
  end

  # Muestra el detalle de un informe
  #
  # * GET /reviews/1
  def show
    @title = t 'review.show_title'

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # Permite ingresar los datos para crear un nuevo informe
  #
  # * GET /reviews/new
  def new
    @title = t 'review.new_title'
    @review = Review.new

    @review.clone_from @review_clone if @review_clone
    @review.period_id = params[:period] ?
      params[:period].to_i : Period.list.first.try(:id)

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # Recupera los datos para modificar un informe
  #
  # * GET /reviews/1/edit
  def edit
    @title = t 'review.edit_title'
  end

  # Crea un nuevo informe siempre que cumpla con las validaciones. Además
  # actualiza el contenido de los objetivos de control que lo componen.
  #
  # * POST /reviews
  def create
    @title = t 'review.new_title'
    @review = Review.list.new(review_params)

    respond_to do |format|
      if @review.save
        flash.notice = t 'review.correctly_created'
        format.html { redirect_to(edit_review_url(@review)) }
      else
        format.html { render action: :new }
      end
    end
  end

  # Actualiza el contenido de un informe siempre que cumpla con las
  # validaciones. Además actualiza el contenido de los objetivos de control que
  # lo componen.
  #
  # * PATCH /reviews/1
  def update
    @title = t 'review.edit_title'

    respond_to do |format|
      if @review.update(review_params)
        flash.notice = t 'review.correctly_updated'
        format.html { redirect_to(edit_review_url(@review)) }
      else
        format.html { render action: :edit }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'review.stale_object_error'
    redirect_to action: :edit
  end

  # Elimina un informe
  #
  # * DELETE /reviews/1
  def destroy
    flash.alert = t 'review.errors.can_not_be_destroyed' unless @review.destroy

    respond_to do |format|
      format.html { redirect_to(reviews_url) }
    end
  end

  # Lista los informes del periodo indicado
  #
  # * GET /reviews/review_data/1.json
  def review_data
    respond_to do |format|
      format.json  { render json: @review.to_json(
        only: [],
          methods: :score_text,
          include: {
            business_unit: { only: :name },
            plan_item: { only: :project }
          }
        )
      }
    end
  end

  # Devuelve los papeles de trabajo del informe
  #
  # * GET /reviews/download_work_papers/1
  def download_work_papers
    @review.zip_all_work_papers current_organization

    redirect_to @review.relative_work_papers_zip_path
  end

  # Devuelve los datos del ítem del plan
  #
  # * GET /reviews/plan_item_data/1
  def plan_item_data
    plan_item = PlanItem.find_by(id: params[:id])
    business_unit = plan_item.try(:business_unit)
    name = business_unit.try(:name)

    type = business_unit.business_unit_type.name if business_unit

    render json: {
      business_unit_name: name,
      business_unit_type: type,
      link_to_suggested_findings:
        (suggested_findings_review_url(id: plan_item.id) if plan_item)
    }.to_json
  end

  # Crea el documento de relevamiento del informe
  #
  # * GET /reviews/survey_pdf/1
  def survey_pdf
    @review.survey_pdf(current_organization)

    redirect_to @review.relative_survey_pdf_path
  end

  # Muestra sugerencias de observaciones / oportunidades de mejora reiteradas
  #
  # * GET /reviews/suggested_findings
  def suggested_findings
    plan_item = PlanItem.find(params[:id])
    @findings = Finding.where(
      [
        "#{Finding.quoted_table_name}.#{Finding.qcn('final')} = :boolean_false",
        "#{Finding.quoted_table_name}.#{Finding.qcn('state')} IN(:states)",
        "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL",
        "#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn('id')} = :business_unit_id"
      ].join(' AND '),
      boolean_false: false,
      states: [
        Finding::STATUS[:being_implemented],
        Finding::STATUS[:implemented],
        Finding::STATUS[:unanswered]
      ],
      business_unit_id: plan_item.business_unit_id
    ).includes(
      control_objective_item: {
        review: [
          {plan_item: [:plan, :business_unit]},
          :period,
          :conclusion_final_review
        ]
      }
    ).order(
      [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ]
    ).references(:reviews, :periods, :conclusion_reviews, :business_units)
  end

  def suggested_process_control_findings
    @process_control = ProcessControl.find params[:id]
    @findings = Finding.where(
      [
        "#{Finding.quoted_table_name}.#{Finding.qcn('organization_id')} = :organization_id",
        "#{Finding.quoted_table_name}.#{Finding.qcn('final')} = :false",
        "#{Finding.quoted_table_name}.#{Finding.qcn('state')} IN(:states)",
        "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL",
        "#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn('process_control_id')} = :process_control_id"
      ].join(' AND '),
      false: false,
      organization_id: Organization.current_id,
      states: [Finding::STATUS[:being_implemented], Finding::STATUS[:implemented]],
      process_control_id: @process_control.id
    ).includes(
      control_objective_item: [
        :control_objective, { review: :conclusion_final_review }
      ]
    ).order(
      [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ]
    ).references(:reviews, :conclusion_reviews, :control_objectives)
  end

  # * GET /reviews/auto_complete_for_finding
  def auto_complete_for_finding
    @tokens = params[:q][0..100].split(
      SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)
    @tokens.reject! { |t| t.blank? }
    conditions = [
      "#{Finding.quoted_table_name}.#{Finding.qcn('final')} = :boolean_false",
      "#{Finding.quoted_table_name}.#{Finding.qcn('state')} IN(:states)",
      "#{Period.quoted_table_name}.#{Period.qcn('organization_id')} = :organization_id",
      "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL"
    ].compact
    parameters = {
      boolean_false: false,
      organization_id: current_organization.id,
      states: [
        Finding::STATUS[:being_implemented], Finding::STATUS[:implemented]
      ],
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{Finding.quoted_table_name}.#{Finding.qcn('review_code')}) LIKE :finding_data_#{i}",
        "LOWER(#{Finding.quoted_table_name}.#{Finding.qcn('title')}) LIKE :finding_data_#{i}",
        "LOWER(#{ControlObjectiveItem.quoted_table_name}.#{ControlObjectiveItem.qcn('control_objective_text')}) LIKE :finding_data_#{i}",
        "LOWER(#{Review.quoted_table_name}.#{Review.qcn('identification')}) LIKE :finding_data_#{i}",
      ].join(' OR ')

      parameters["finding_data_#{i}".to_sym] = "%#{t.mb_chars.downcase}%"
    end

    @findings = Finding.includes(
      control_objective_item: {review: [:period, :conclusion_final_review]}
    ).where([conditions.map {|c| "(#{c})"}.join(' AND '), parameters]).order(
      [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ]
    ).references(
      :reviews, :control_objective_items, :periods, :conclusion_reviews
    ).limit(5)

    respond_to do |format|
      format.json { render json: @findings }
    end
  end

  # * GET /reviews/auto_complete_for_control_objective
  def auto_complete_for_control_objective
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}

    conditions = [
      [
        [
          "#{BestPractice.table_name}.#{BestPractice.qcn 'shared'} = :false",
          "#{BestPractice.table_name}.#{BestPractice.qcn 'organization_id'} = :organization_id"
        ].join(' AND '),
        [
          "#{BestPractice.table_name}.#{BestPractice.qcn 'shared'} = :true",
          "#{BestPractice.table_name}.#{BestPractice.qcn 'group_id'} = :group_id"
        ].join(' AND ')
      ].map { |c| "(#{c})" }.join(' OR '),
      "#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn('obsolete')} = :false"
    ]
    parameters = {
      false:           false,
      true:            true,
      organization_id: Organization.current_id,
      group_id:        Group.current_id
    }

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn('name')}) LIKE :control_objective_data_#{i}",
        "LOWER(#{ProcessControl.quoted_table_name}.#{ProcessControl.qcn('name')}) LIKE :control_objective_data_#{i}"
      ].join(' OR ')

      parameters[:"control_objective_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @control_objectives = ControlObjective.includes(
      process_control: :best_practice
    ).where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order(
      [
        "#{ProcessControl.quoted_table_name}.#{ProcessControl.qcn('name')} ASC",
        "#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn('order')} ASC"
      ]
    ).references(:best_practices, :process_control).limit(10)

    respond_to do |format|
      format.json { render json: @control_objectives }
    end
  end

  # * GET /reviews/estimated_amount/1
  def estimated_amount
    plan_item = PlanItem.find(params[:id]) unless params[:id].blank?

    render partial: 'estimated_amount', locals: {plan_item: plan_item}
  end

  # * PUT /reviews/1/recode_findings
  def recode_findings
    @review.recode_weaknesses
    @review.recode_oportunities

    redirect_to @review, notice: t('review.findings_recoded')
  end

  # * PUT /reviews/1/recode_findings_by_risk
  def recode_findings_by_risk
    @review.recode_weaknesses_by_risk
    @review.recode_oportunities_by_risk

    redirect_to @review, notice: t('review.findings_recoded')
  end

  # * GET /reviews/next_identification_number
  def next_identification_number
    @next_number = Review.next_identification_number params[:suffix]
  end

  private

    def review_params
      params.require(:review).permit(
        :identification, :description, :survey, :period_id, :plan_item_id,
        :scope, :risk_exposure, :manual_score, :include_sox, :lock_version,
        file_model_attributes: [:id, :file, :file_cache, :_destroy],
        finding_review_assignments_attributes: [
          :id, :finding_id, :_destroy, :lock_version
        ],
        review_user_assignments_attributes: [
          :id, :assignment_type, :user_id, :include_signature, :owner, :_destroy
        ],
        taggings_attributes: [
          :id, :tag_id, :_destroy
        ],
        control_objective_items_attributes: [
          :id, :control_objective_id, :control_objective_text, :relevance, :order_number, :_destroy,
          control_attributes: [
            :control, :effects, :design_tests, :compliance_tests, :sustantive_tests
          ]
        ],
        control_objective_ids: [],
        process_control_ids: []
      )
    end

    def set_review
      @review = Review.list.includes(
        { plan_item: :business_unit },
        { review_user_assignments: :user },
        { finding_review_assignments: :finding },
        { control_objective_items:
          [
            :control,
            { control_objective: :process_control }
          ]
        }
      ).find(params[:id])
    end

    def set_review_clone
      @review_clone = Review.list.find_by(id: params[:clone_from].try(:to_i))
    end

    def load_privileges
      @action_privileges.update(
        review_data: :read,
        download_work_papers: :read,
        plan_item_data: :read,
        survey_pdf: :read,
        suggested_findings: :read,
        auto_complete_for_finding: :read,
        auto_complete_for_control_objective: :read,
        auto_complete_for_process_control: :read,
        auto_complete_for_tagging: :read,
        estimated_amount: :read,
        next_identification_number: :read,
        recode_findings: :modify,
        recode_findings_by_risk: :modify
      )
    end
end
