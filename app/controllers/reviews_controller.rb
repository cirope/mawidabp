class ReviewsController < ApplicationController
  include AutoCompleteFor::User

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_review, only: [
    :show, :edit, :update, :destroy, :review_data, :download_work_papers,
    :survey_pdf
  ]
  before_action :set_review_clone, only: [:new]
  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # Lista los informes
  #
  # * GET /reviews
  # * GET /reviews.xml
  def index
    @title = t 'review.index_title'

    build_search_conditions Review

    @reviews = Review.list.includes(
      :period, { plan_item: :business_unit }
    ).where(@conditions).reorder('identification DESC').page(
      params[:page]
    ).references(:periods)

    respond_to do |format|
      format.html {
        if @reviews.count == 1 && !@query.blank? && !params[:page]
          redirect_to review_url(@reviews.first)
        end
      }
      format.xml  { render xml: @reviews }
    end
  end

  # Muestra el detalle de un informe
  #
  # * GET /reviews/1
  # * GET /reviews/1.xml
  def show
    @title = t 'review.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @review }
    end
  end

  # Permite ingresar los datos para crear un nuevo informe
  #
  # * GET /reviews/new
  # * GET /reviews/new.xml
  def new
    @title = t 'review.new_title'
    @review = Review.new

    @review.clone_from @review_clone if @review_clone
    @review.period_id = params[:period] ?
      params[:period].to_i : Period.list.first.try(:id)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @review }
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
  # * POST /reviews.xml
  def create
    @title = t 'review.new_title'
    @review = Review.list.new(review_params)

    respond_to do |format|
      if @review.save
        flash.notice = t 'review.correctly_created'
        format.html { redirect_to(edit_review_url(@review)) }
        format.xml  { render xml: @review, status: :created, location: @review }
      else
        format.html { render action: :new }
        format.xml  { render xml: @review.errors, status: :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un informe siempre que cumpla con las
  # validaciones. Además actualiza el contenido de los objetivos de control que
  # lo componen.
  #
  # * PATCH /reviews/1
  # * PATCH /reviews/1.xml
  def update
    @title = t 'review.edit_title'

    respond_to do |format|
      if @review.update(review_params)
        flash.notice = t 'review.correctly_updated'
        format.html { redirect_to(edit_review_url(@review)) }
        format.xml  { head :ok }
      else
        format.html { render action: :edit }
        format.xml  { render xml: @review.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'review.stale_object_error'
    redirect_to action: :edit
  end

  # Elimina un informe
  #
  # * DELETE /reviews/1
  # * DELETE /reviews/1.xml
  def destroy
    flash.alert = t 'review.errors.can_not_be_destroyed' unless @review.destroy

    respond_to do |format|
      format.html { redirect_to(reviews_url) }
      format.xml  { head :ok }
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

  # Devuelve los datos del procedimiento y prueba de control
  #
  # * GET /reviews/procedure_control_data/1
  def procedure_control_data
    @procedure_control = ProcedureControl.includes(:period).where(
      id: params[:id],
      "#{Period.table_name}.organization_id" => current_organization.id
    ).references(:periods).first

    render template: 'procedure_controls/show'
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
        "#{Finding.table_name}.final = :boolean_false",
        "#{Finding.table_name}.state IN(:states)",
        "#{ConclusionReview.table_name}.review_id IS NOT NULL",
        "#{BusinessUnit.table_name}.id = :business_unit_id"
      ].join(' AND '),
      boolean_false: false,
      states: [
        Finding::STATUS[:being_implemented], Finding::STATUS[:implemented]
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
        "#{Review.table_name}.identification ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    ).references(:reviews, :periods, :conclusion_reviews, :business_units)
  end

  # * GET /reviews/auto_complete_for_finding
  def auto_complete_for_finding
    @tokens = params[:q][0..100].split(
      SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)
    @tokens.reject! { |t| t.blank? }
    conditions = [
      "#{Finding.table_name}.final = :boolean_false",
      "#{Finding.table_name}.state IN(:states)",
      "#{Period.table_name}.organization_id = :organization_id",
      "#{ConclusionReview.table_name}.review_id IS NOT NULL"
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
        "LOWER(#{Finding.table_name}.review_code) LIKE :finding_data_#{i}",
        "LOWER(#{Finding.table_name}.description) LIKE :finding_data_#{i}",
        "LOWER(#{ControlObjectiveItem.table_name}.control_objective_text) LIKE :finding_data_#{i}",
        "LOWER(#{Review.table_name}.identification) LIKE :finding_data_#{i}",
      ].join(' OR ')

      parameters["finding_data_#{i}".to_sym] = "%#{t.mb_chars.downcase}%"
    end

    @findings = Finding.includes(
      control_objective_item: {review: [:period, :conclusion_final_review]}
    ).where([conditions.map {|c| "(#{c})"}.join(' AND '), parameters]).order(
      [
        "#{Review.table_name}.identification ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    ).references(
      :reviews, :control_objective_items, :periods, :conclusion_reviews
    ).limit(5)

    respond_to do |format|
      format.json { render json: @findings }
    end
  end

  # * GET /reviews/auto_complete_for_procedure_control_subitem
  def auto_complete_for_procedure_control_subitem
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{BestPractice.table_name}.organization_id = :organization_id",
      "#{ProcedureControl.table_name}.period_id = :period_id"
    ]
    parameters = {organization_id: current_organization.id}
    parameters[:period_id] = params[:period_id] unless params[:period_id].blank?

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{ProcedureControlSubitem.table_name}.control_objective_text) LIKE :procedure_control_subitem_data_#{i}",
        "LOWER(#{ProcessControl.table_name}.name) LIKE :procedure_control_subitem_data_#{i}"
      ].join(' OR ')

      parameters[:"procedure_control_subitem_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @procedure_control_subitems = ProcedureControlSubitem.includes(
      control_objective: {process_control: :best_practice},
      procedure_control_item: :procedure_control
    ).where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order(
      [
        "#{ProcessControl.table_name}.name ASC",
        "#{ControlObjective.table_name}.name ASC"
      ]
    ).references(:best_practices, :procedure_controls, :control_objectives).limit(10)

    respond_to do |format|
      format.json { render json: @procedure_control_subitems }
    end
  end

  # * GET /reviews/estimated_amount/1
  def estimated_amount
    plan_item = PlanItem.find(params[:id]) unless params[:id].blank?

    render partial: 'estimated_amount', locals: {plan_item: plan_item}
  end

  private
    def review_params
      params.require(:review).permit(
        :identification, :description, :survey, :period_id, :plan_item_id,
        :procedure_control_subitem_ids, :lock_version,
        file_model_attributes: [:id, :file, :file_cache, :_destroy],
        finding_review_assignments_attributes: [
          :id, :finding_id, :_destroy, :lock_version
        ],
        review_user_assignments_attributes: [
          :id, :assignment_type, :user_id, :_destroy
        ],
        control_objective_items_attributes: [
          :id, :control_objective_id, :control_objective_text, :order_number, :_destroy,
          control_attributes: [
            :control, :effects, :design_tests, :compliance_tests, :sustantive_tests
          ]
        ],
        procedure_control_subitem_ids: []
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
        procedure_control_data: :read,
        survey_pdf: :read,
        suggested_findings: :read,
        auto_complete_for_user: :read,
        auto_complete_for_finding: :read,
        auto_complete_for_procedure_control_subitem: :read,
        estimated_amount: :read
      )
    end
end
