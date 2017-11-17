class ConclusionFinalReviewsController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges
  before_action :set_conclusion_final_review, only: [
    :show, :edit, :update, :export_to_pdf, :score_sheet, :download_work_papers,
    :create_bundle, :compose_email, :send_by_email
  ]
  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  def index
    @title = t 'conclusion_final_review.index_title'

    build_search_conditions ConclusionFinalReview

    order = @order_by || "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn('issue_date')} DESC"
    order << ", #{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn('created_at')} DESC"

    @conclusion_final_reviews = ConclusionFinalReview.list.includes(
      review: [:period, { plan_item: :business_unit }]
    ).where(@conditions).order(order).page(params[:page])
    .references(:periods, :reviews, :business_units)

    respond_to do |format|
      format.html
    end
  end

  # Muestra el detalle de un informe definitivo
  #
  # * GET /conclusion_final_reviews/1
  def show
    @title = t 'conclusion_final_review.show_title'

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # Permite ingresar los datos para crear un nuevo informe definitivo
  #
  # * GET /conclusion_final_reviews/new
  # * GET /conclusion_final_reviews/new.json
  def new
    conclusion_final_review =
      ConclusionFinalReview.list.find_by(review_id: params[:review])

    unless conclusion_final_review
      @title = t 'conclusion_final_review.new_title'
      @conclusion_final_review =
        ConclusionFinalReview.new(review_id: params[:review])

      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @conclusion_final_review.to_json(
            include: {review: {
                only: [],
                methods: :score_text,
                include: {
                  business_unit: {only: :name},
                  plan_item: {only: :project}
                },
              }
            },
            only: [
              :conclusion,
              :applied_procedures,
              :evolution,
              :evolution_justification,
              :recipients,
              :sectors
            ])
        }
      end
    else
      redirect_to edit_conclusion_final_review_url(conclusion_final_review)
    end
  end

  # Recupera los datos para modificar un informe definitivo
  #
  # * GET /conclusion_final_reviews/1/edit
  def edit
    @title = t 'conclusion_final_review.edit_title'
  end

  # Crea un nuevo informe definitivo siempre que cumpla con las validaciones.
  #
  # * POST /conclusion_final_reviews
  def create
    @title = t 'conclusion_final_review.new_title'
    @conclusion_final_review =
      ConclusionFinalReview.list.new(conclusion_final_review_params, false)

    respond_to do |format|
      if @conclusion_final_review.save
        flash.notice = t 'conclusion_final_review.correctly_created'
        format.html { redirect_to(conclusion_final_reviews_url) }
      else
        format.html { render action: :new }
      end
    end
  end

  # Actualiza el contenido de un informe definitivo siempre que cumpla con las
  # validaciones.
  #
  # * PATCH /conclusion_final_reviews/1
  def update
    @title = t 'conclusion_final_review.edit_title'

    respond_to do |format|
      if @conclusion_final_review.update(conclusion_final_review_params)
        flash.notice = t 'conclusion_final_review.correctly_updated'
        format.html { redirect_to(conclusion_final_reviews_url) }
      else
        format.html { render action: :edit }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'conclusion_final_review.stale_object_error'
    redirect_to action: :edit
  end

  # Exporta el informe en formato PDF
  #
  # * GET /conclusion_final_reviews/export_to_pdf/1
  def export_to_pdf
    if SHOW_CONCLUSION_ALTERNATIVE_PDF
      @conclusion_final_review.alternative_pdf(current_organization)
    else
      @conclusion_final_review.to_pdf(current_organization, params[:export_options]&.to_unsafe_h)
    end

    respond_to do |format|
      format.html { redirect_to @conclusion_final_review.relative_pdf_path }
    end
  end

  # Crea la planilla de calificación del informe en formato PDF
  #
  # * GET /conclusion_final_reviews/score_sheet/1
  def score_sheet
    review = @conclusion_final_review.review

    if params[:global].blank?
      review.score_sheet(current_organization)

      redirect_to review.relative_score_sheet_path
    else
      review.global_score_sheet(current_organization)

      redirect_to review.relative_global_score_sheet_path
    end
  end

  # Devuelve los papeles de trabajo del informe
  #
  # * GET /conclusion_final_reviews/download_work_papers/1
  def download_work_papers
    review = @conclusion_final_review.review
    review.zip_all_work_papers current_organization

    redirect_to review.relative_work_papers_zip_path
  end

  # Crea el legajo completo del informe
  #
  # * POST /conclusion_final_reviews/create_bundle
  def create_bundle
    @conclusion_final_review.create_bundle_zip current_organization,
      params[:index_items]

    @report_path = @conclusion_final_review.relative_bundle_zip_path

    respond_to do |format|
      format.html { redirect_to @report_path }
      format.js { render 'shared/pdf_report' }
    end
  end

  # Confecciona el correo con el informe
  #
  # * GET /conclusion_final_reviews/compose_email/1
  def compose_email
    @title = t 'conclusion_final_review.send_by_email'
    @questionnaires = Questionnaire.list.by_pollable_type 'ConclusionReview'
  end

  # Envia por correo el informe a los usuarios indicados
  #
  # * POST /conclusion_final_reviews/send_by_email/1
  def send_by_email
    @title = t 'conclusion_final_review.send_by_email'

    @questionnaires = Questionnaire.list.by_pollable_type 'ConclusionReview'

    users = []
    users_with_poll = []
    export_options = params[:export_options] || {}

    if params[:conclusion_review]
      include_score_sheet = params[:conclusion_review][:include_score_sheet] == '1'
      include_global_score_sheet = params[:conclusion_review][:include_global_score_sheet] == '1'
      note = params[:conclusion_review][:email_note]
      review_type = params[:conclusion_review][:review_type]

      if review_type == 'brief'
        export_options[:brief] = '1'
      elsif review_type == 'without_score'
        export_options[:hide_score] = '1'
      end
    end

    if SHOW_CONCLUSION_ALTERNATIVE_PDF
      @conclusion_final_review.alternative_pdf(current_organization)
    else
      @conclusion_final_review.to_pdf(current_organization, export_options)
    end

    if include_score_sheet
      @conclusion_final_review.review.score_sheet current_organization
    end

    if include_global_score_sheet
      @conclusion_final_review.review.global_score_sheet(current_organization)
    end

    (params[:user].try(:values).try(:reject, &:blank?) || []).each do |user_data|
      user = User.find_by(id: user_data[:id]) if user_data[:id]
      send_options = {
        note: note,
        include_score_sheet: include_score_sheet,
        include_global_score_sheet: include_global_score_sheet
      }

      if user && users.all? { |u| u.id != user.id }
        @conclusion_final_review.send_by_email_to(user, send_options)

        users << user
      end

      if user.try(:can_act_as_audited?) && user_data[:questionnaire_id].present?
        questionnaire = Questionnaire.find user_data[:questionnaire_id]
        affected_user_id = user_data[:affected_user_id].present? ?
          user_data[:affected_user_id] : nil
        has_poll = Poll.list.exists?(
          user_id: user.id,
          affected_user_id: affected_user_id,
          questionnaire_id: user_data[:questionnaire_id],
          organization_id: current_organization.id,
          pollable_type: questionnaire.pollable_type,
          pollable_id: @conclusion_final_review
        )

        if has_poll
          users_with_poll << user.informal_name
        else
          @conclusion_final_review.polls.create!(
            user_id: user.id,
            affected_user_id: affected_user_id,
            questionnaire_id: user_data[:questionnaire_id],
            organization_id: current_organization.id,
            pollable_type: questionnaire.pollable_type
          )
        end
      end
    end

    if users.present?
      flash.notice = t('conclusion_review.review_sended')

      if users_with_poll.present?
        flash.notice << ". #{t 'polls.already_exists', user: users_with_poll.uniq.to_sentence}"
      end

      redirect_to edit_conclusion_final_review_url(@conclusion_final_review)
    else
      render action: :compose_email
    end
  end

  # Lista las informes en un PDF
  #
  # * GET /conclusion_final_reviews/export_to_pdf
  def export_list_to_pdf
    build_search_conditions ConclusionFinalReview

    conclusion_final_reviews = ConclusionFinalReview.list.includes(
      review: [:period, { plan_item: :business_unit }]
    ).where(@conditions).references(:periods, :reviews, :business_units).order(
      @order_by || "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn('issue_date')} DESC"
    )

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header current_organization
    pdf.add_title t('conclusion_final_review.index_title')

    column_order = [
      ['period', Review.human_attribute_name(:period_id), 5],
      ['identification', Review.human_attribute_name(:identification), 13],
      ['summary', ConclusionDraftReview.human_attribute_name(:summary), 10],
      ['business_unit', PlanItem.human_attribute_name(:business_unit_id), 20],
      ['project', PlanItem.human_attribute_name(:project), 25],
      ['issue_date', ConclusionDraftReview.human_attribute_name(:issue_date), 10],
      ['close_date', ConclusionDraftReview.human_attribute_name(:close_date), 10],
      ['score', Review.human_attribute_name(:score), 7]
    ]

    columns = {}
    column_data, column_headers, column_widths = [], [], []

    column_order.each do |col_data|
      column_headers << col_data[1]
      column_widths << pdf.percent_width(col_data[2])
    end

    conclusion_final_reviews.each do |cfr|
      column_data << [
        cfr.review.period.name,
        cfr.review.identification,
        cfr.summary,
        cfr.review.plan_item.business_unit.name,
        cfr.review.plan_item.project,
        "<b>#{cfr.issue_date ? l(cfr.issue_date, format: :minimal) : ''}</b>",
        (cfr.close_date ? l(cfr.close_date, format: :minimal) : ''),
        cfr.review.score.to_s + '%'
      ]
    end

    unless @columns.blank? || @query.blank?
      pdf.move_down PDF_FONT_SIZE
      pointer_moved = true
      filter_columns = @columns.map do |c|
        column_name = column_order.detect { |co| co[0] == c }
        "<b>#{column_name[1]}</b>"
      end

      pdf.text t('conclusion_final_review.pdf.filtered_by',
        query: @query.flatten.map { |q| "<b>#{q}</b>"}.join(', '),
        columns: filter_columns.to_sentence, count: @columns.size),
        font_size: (PDF_FONT_SIZE * 0.75).round, inline_format: true
    end

    unless @order_by_column_name.blank?
      pdf.move_down PDF_FONT_SIZE unless pointer_moved
      pdf.text t('conclusion_final_review.pdf.sorted_by',
        column: "<b>#{@order_by_column_name}</b>"),
        font_size: (PDF_FONT_SIZE * 0.75).round
    end

    pdf.move_down PDF_FONT_SIZE

    unless column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    pdf_name = t 'conclusion_final_review.pdf.pdf_name'

    pdf.custom_save_as(pdf_name, ConclusionFinalReview.table_name)

    redirect_to Prawn::Document.relative_path(pdf_name, ConclusionFinalReview.table_name)
  end

  private
    def set_conclusion_final_review
      @conclusion_final_review = ConclusionFinalReview.list.includes(
        review: [
          :period,
          :plan_item,
          {
            control_objective_items: [
              :control, :final_weaknesses, :final_oportunities
            ]
          }
        ]
      ).find(params[:id])
    end

    def conclusion_final_review_params
      params.require(:conclusion_final_review).permit(
        :review_id, :issue_date, :close_date, :applied_procedures, :conclusion,
        :summary, :recipients, :evolution, :evolution_justification, :sectors,
        :lock_version
      )
    end

    def load_privileges
      @action_privileges.update({
          export_to_pdf: :read,
          score_sheet: :read,
          download_work_papers: :read,
          bundle: :read,
          create_bundle: :read,
          export_list_to_pdf: :read,
          compose_email: :modify,
          send_by_email: :modify
        })
    end
end
