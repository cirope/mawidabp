class ConclusionDraftReviewsController < ApplicationController
  include Reviews::Permissions

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_conclusion_draft_review, only: [
    :show, :edit, :update, :export_to_pdf, :export_to_rtf,
    :score_sheet, :download_work_papers, :create_bundle,
    :compose_email, :send_by_email
  ]
  before_action -> { check_review_permissions @conclusion_draft_review }, only: [:edit, :update]
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista los informes borradores
  #
  # * GET /conclusion_draft_reviews
  def index
    @title = t 'conclusion_draft_review.index_title'

    @conclusion_draft_reviews = ConclusionDraftReview.list.includes(
      review: [
        :period,
        :conclusion_final_review,
        plan_item: :business_unit
      ]
    ).search(
      **search_params
    ).references(
      :reviews, :business_units
    ).merge(
      PlanItem.allowed_by_business_units_and_auxiliar_business_units_types
    ).merge(
      Review.scoped_for ConclusionDraftReview, @auth_user
    ).order_by.page params[:page]

    respond_to do |format|
      format.html
    end
  end

  # Muestra el detalle de un informe borrador
  #
  # * GET /conclusion_draft_reviews/1
  def show
    @title = t 'conclusion_draft_review.show_title'

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # Permite ingresar los datos para crear un nuevo informe borrador
  #
  # * GET /conclusion_draft_reviews/new
  def new
    @title = t 'conclusion_draft_review.new_title'
    @conclusion_draft_review =
      ConclusionDraftReview.new(review_id: params[:review])

    @conclusion_draft_review.review&.build_best_practice_comments

    respond_to do |format|
      format.html # new.html.erb
      format.js   # new.js.erb
    end
  end

  # Recupera los datos para modificar un informe borrador
  #
  # * GET /conclusion_draft_reviews/1/edit
  def edit
    @title = t 'conclusion_draft_review.edit_title'

    @conclusion_draft_review.review.build_best_practice_comments
  end

  # Crea un nuevo informe borrador siempre que cumpla con las validaciones.
  #
  # * POST /conclusion_draft_reviews
  def create
    @title = t 'conclusion_draft_review.new_title'
    @conclusion_draft_review = ConclusionDraftReview.list.new(
      conclusion_draft_review_params)

    respond_to do |format|
      if @conclusion_draft_review.save
        flash.notice = t 'conclusion_draft_review.correctly_created'
        format.html { redirect_to(edit_conclusion_draft_review_url(@conclusion_draft_review)) }
      else
        format.html { render action: :new }
      end
    end
  end

  # Actualiza el contenido de un informe borrador siempre que cumpla con las
  # validaciones.
  #
  # * PATCH /conclusion_draft_reviews/1
  def update
    @title = t 'conclusion_draft_review.edit_title'

    respond_to do |format|
      if @conclusion_draft_review.update(conclusion_draft_review_params)
        flash.notice = t 'conclusion_draft_review.correctly_updated'
        format.html { redirect_to(edit_conclusion_draft_review_url(@conclusion_draft_review)) }
      else
        format.html { render action: :edit }
      end
    end

    rescue ActiveRecord::StaleObjectError
      flash.alert = t 'conclusion_draft_review.stale_object_error'
      redirect_to edit_conclusion_draft_review_url(@conclusion_draft_review)
  end

  # Exporta el informe en formato PDF
  #
  # * GET /conclusion_draft_reviews/export_to_pdf/1
  def export_to_pdf
    options = params[:export_options]&.to_unsafe_h

    @conclusion_draft_review.to_pdf(current_organization, options)

    respond_to do |format|
      format.html { redirect_to @conclusion_draft_review.relative_pdf_path }
    end
  end

  # Exporta el informe en formato RTF
  #
  # * GET /conclusion_draft_reviews/export_to_rtf/1
  def export_to_rtf
    respond_to do |format|
      format.rtf do
        render rtf: @conclusion_draft_review.to_rtf(current_organization),
               filename: @conclusion_draft_review.rtf_name
      end
    end
  end

  # Crea la planilla de calificación del informe en formato PDF
  #
  # * GET /conclusion_draft_reviews/score_sheet/1
  def score_sheet
    review = @conclusion_draft_review.review

    if params[:global].blank?
      review.score_sheet(current_organization, draft: true)

      redirect_to review.relative_score_sheet_path
    else
      review.global_score_sheet(current_organization, draft: true)

      redirect_to review.relative_global_score_sheet_path
    end
  end

  # Devuelve los papeles de trabajo del informe
  #
  # * GET /conclusion_draft_reviews/download_work_papers/1
  def download_work_papers
    review = @conclusion_draft_review.review
    review.zip_all_work_papers current_organization

    redirect_to review.relative_work_papers_zip_path
  end

  # Crea el legajo completo del informe
  #
  # * POST /conclusion_draft_reviews/create_bundle
  def create_bundle
    @conclusion_draft_review.create_bundle_zip current_organization,
      params[:index_items]

    @report_path = @conclusion_draft_review.relative_bundle_zip_path

    respond_to do |format|
      format.html { redirect_to @report_path }
      format.js { render 'shared/pdf_report' }
    end
  end

  # Confecciona el correo con el informe
  #
  # * GET /conclusion_draft_reviews/compose_email/1
  def compose_email
    @title = t 'conclusion_draft_review.send_by_email'
  end

  # Envia por correo el informe a los usuarios indicados
  #
  # * POST /conclusion_draft_reviews/send_by_email/1
  def send_by_email
    @title = t 'conclusion_draft_review.send_by_email'

    if @conclusion_draft_review.try(:review).try(:can_be_sended?)
      users          = []
      export_options = params[:export_options] || {}

      if params[:conclusion_review]
        include_score_sheet        = params[:conclusion_review][:include_score_sheet] == '1'
        include_global_score_sheet = params[:conclusion_review][:include_global_score_sheet] == '1'
        note                       = params[:conclusion_review][:email_note]
        review_type                = params[:conclusion_review][:review_type]

        if review_type == 'brief'
          export_options[:brief] = '1'
        elsif review_type == 'without_score'
          export_options[:hide_score] = '1'
        end
      end

      pdf_info = @conclusion_draft_review.to_pdf(current_organization, export_options)

      if include_score_sheet
        @conclusion_draft_review.review.score_sheet current_organization, draft: true
      end

      if include_global_score_sheet
        @conclusion_draft_review.review.global_score_sheet(current_organization, draft: true)
      end

      if include_executive_summary?
        executive_summary_pages = pdf_info[:executive_summary_pages]
        pdf_path                = @conclusion_draft_review.absolute_pdf_path
        pdf                     = MiniMagick::Image.open(pdf_path)

        executive_summary_pages.times do |page|
          image_path = "#{pdf_path}_#{page}.png"

          MiniMagick::Tool::Convert.new do |convert|
            convert.background "white"
            convert.flatten
            convert.density 300
            convert.quality 100
            convert << pdf.pages[page].path
            convert << "png32:#{image_path}"
          end
        end
      end

      (params[:user].try(:values).try(:reject, &:blank?) || []).each do |user_data|
        user = User.find_by(id: user_data[:id]) if user_data[:id]
        send_options = {
          note: note,
          include_score_sheet: include_score_sheet,
          include_global_score_sheet: include_global_score_sheet
        }

        if include_executive_summary?
          send_options[:executive_summary_pages] = executive_summary_pages
        end

        if user && !users.include?(user)
          @conclusion_draft_review.send_by_email_to(user, send_options)

          users << user
        end
      end

      unless users.blank?
        flash.notice = t('conclusion_review.review_sended')

        redirect_to edit_conclusion_draft_review_url(
          @conclusion_draft_review)
      else
        render action: :compose_email
      end
    elsif @conclusion_draft_review.try(:review)
      flash.alert = t('conclusion_review.review_not_approved')
      render action: :compose_email
    else
      redirect_to conclusion_draft_reviews_url
    end
  end

  def check_for_approval
    if params[:id] && params[:id].to_i > 0
      review = Review.includes(:period).where(
        id: params[:id],
        "#{Period.table_name}.organization_id" => current_organization.id
      ).references(:periods).first

      response = {
        approved: review.is_approved?,
        can_be_approved_by_force: review.can_be_approved_by_force,
        errors: review.approval_errors
      }
    else
      response = {}
    end

    respond_to do |format|
      format.json { render json: response }
    end
  end

  def corrective_actions_update
    respond_to do |format|
      format.js
    end
  end

  private

    def set_conclusion_draft_review
      @conclusion_draft_review = ConclusionDraftReview.list.includes(
        review: [
          :period,
          :conclusion_final_review,
          :plan_item,
          { control_objective_items: [:control, :weaknesses, :oportunities] }
        ]
      ).merge(
        Review.scoped_for ConclusionDraftReview, @auth_user
      ).find(
        params[:id]
      )

      @conclusion_draft_review = nil if @conclusion_draft_review.has_final_review?
    end

    def conclusion_draft_review_params
      params.require(:conclusion_draft_review).permit(
        :review_id, :issue_date, :close_date, :applied_procedures, :conclusion,
        :recipients, :sectors, :evolution, :evolution_justification,
        :observations, :main_weaknesses_text, :corrective_actions,
        :affects_compliance, :collapse_control_objectives, :force_approval,
        :reference, :scope, :previous_identification, :previous_date,
        :main_recommendations, :effectiveness_notes, :additional_comments,
        :review_conclusion, :applied_data_analytics, :work_scope,
        :lock_version, :exclude_regularized_findings,
        review_attributes: [
          :id, :manual_score, :description, :lock_version,
          best_practice_comments_attributes: [
            :id, :best_practice_id, :auditor_comment
          ]
        ],
        annexes_attributes: [
          :id, :title, :description, :_destroy,
          image_models_attributes: [
            :id, :image, :image_cache, :_destroy
          ]
        ]
      )
    end

    def load_privileges
      @action_privileges.update(
        export_to_pdf: :read,
        score_sheet: :read,
        download_work_papers: :read,
        bundle: :read,
        create_bundle: :read,
        check_for_approval: :read,
        compose_email: :modify,
        send_by_email: :modify
      )
    end

    def include_executive_summary?
      draft_issue_date = @conclusion_draft_review.issue_date
      code_change_date = CONCLUSION_REVIEW_FEATURE_DATES['exec_summary_v2']&.to_date

      Current.conclusion_pdf_format == 'gal' && code_change_date && draft_issue_date >= code_change_date
    end
end
