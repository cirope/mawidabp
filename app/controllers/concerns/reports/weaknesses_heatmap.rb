module Reports::WeaknessesHeatmap
  extend ActiveSupport::Concern

  include Reports::FileResponder
  include Reports::Pdf
  include Reports::Period

  def weaknesses_heatmap
    init_weaknesses_heatmap_vars

    respond_to do |format|
      format.html { render_paginated_weaknesses }
      format.js   { render_paginated_weaknesses }
      format.csv  { render_weaknesses_heatmap_report_csv }
    end
  end

  def create_weaknesses_heatmap
    init_weaknesses_heatmap_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @weaknesses.any?
      @weaknesses.each do |weakness|
        weaknesses_heatmap_pdf_items(weakness).each do |item|
          text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

          pdf.text text, size: PDF_FONT_SIZE, inline_format: true, align: :justify
        end

        pdf.text "#{t('finding.finding_answers')}:", size: PDF_FONT_SIZE,
          style: :italic

        pdf.indent PDF_FONT_SIZE do
          weakness.finding_answers.each do |finding_answer|
            pdf.move_down PDF_FONT_SIZE * 0.5

            footer = [
              finding_answer.user.full_name,
              l(finding_answer.created_at, format: :minimal)
            ]

            pdf.text finding_answer.answer
            pdf.text footer.join(' - '), size: (PDF_FONT_SIZE * 0.75).round,
              align: :justify, color: '777777'
          end
        end

        pdf.move_down PDF_FONT_SIZE
      end
    else
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t("#{@controller}_committee_report.weaknesses_heatmap.without_weaknesses"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_heatmap')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_heatmap')
  end

  private

    def init_weaknesses_heatmap_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.weaknesses_heatmap_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_heatmap])
      @filters = []
      final = params[:final] == 'true'
      order = [
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'origination_date'} ASC",
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'conclusion_index'} DESC"
      ].map { |o| Arel.sql o }
      weaknesses = Weakness.
        with_status_for_report.
        finals(final).
        list_for_report.
        by_issue_date('BETWEEN', @from_date, @to_date).
        includes(
          :business_unit,
          :business_unit_type,
          finding_answers: :user,
          review: [:plan_item, :conclusion_final_review]
        )

      if params[:weaknesses_heatmap]
        weaknesses = filter_weaknesses_heatmap weaknesses
        weaknesses = filter_weaknesses_heatmap_by_risk weaknesses
        weaknesses = filter_weaknesses_heatmap_by_status weaknesses
        weaknesses = filter_weaknesses_heatmap_by_title weaknesses
        weaknesses = filter_weaknesses_heatmap_by_business_unit_type weaknesses
      end

      @weaknesses = weaknesses.reorder order
    end

    def render_weaknesses_heatmap_report_csv
      render_or_send_by_mail(
        collection:  @weaknesses,
        filename:    "#{@title.downcase}.csv",
        method_name: :weaknesses_heatmap_csv
      )
    end

    def weaknesses_heatmap_pdf_items weakness
      [
        [
          Review.model_name.human,
          weakness.review.identification
        ],
        [
          PlanItem.human_attribute_name('project'),
          weakness.review.plan_item.project
        ],
        [
          ConclusionFinalReview.human_attribute_name('issue_date'),
          weakness.review.conclusion_final_review ? l(weakness.review.conclusion_final_review.issue_date) : '-'
        ],
        [
          BusinessUnit.model_name.human,
          weakness.business_unit
        ],
        [
          Weakness.human_attribute_name('review_code'),
          weakness.review_code
        ],
        [
          Weakness.human_attribute_name('title'),
          weakness.title
        ],
        [
          Weakness.human_attribute_name('description'),
          weakness.description
        ],
        [
          Weakness.human_attribute_name('state'),
          weakness.state_text
        ],
        [
          Weakness.human_attribute_name('risk'),
          weakness.risk_text
        ],
        [
          PlanItem.human_attribute_name('risk_exposure'),
          weakness.review.plan_item.risk_exposure
        ],
        [
          Weakness.human_attribute_name('priority'),
          weakness.priority_text
        ],
        [
          t('finding.auditors', count: 0),
          weakness.users.select(&:auditor?).map(&:full_name).to_sentence
        ],
        [
          t('finding.responsibles', count: 1),
          weakness.process_owners.map(&:full_name).to_sentence
        ],
        [
          t('finding.audited', count: 0),
          weakness.users.select { |u|
            u.can_act_as_audited? && weakness.process_owners.exclude?(u)
          }.map(&:full_name).to_sentence
        ],
        [
          Weakness.human_attribute_name('origination_date'),
          (weakness.origination_date ? l(weakness.origination_date) : '-')
        ],
        [
          Weakness.human_attribute_name('follow_up_date'),
          (weakness.follow_up_date ? l(weakness.follow_up_date) : '-')
        ],
        [
          Weakness.human_attribute_name('solution_date'),
          (weakness.solution_date ? l(weakness.solution_date) : '-')
        ],
        [
          Weakness.human_attribute_name('rescheduled'),
          t("label.#{weakness.rescheduled? ? 'yes' : 'no'}")
        ],
        [
          t('findings.state.repeated'),
          t("label.#{weakness.repeated_of_id.present? ? 'yes' : 'no'}")
        ],
        [
          Weakness.human_attribute_name('audit_comments'),
          weakness.audit_comments
        ],
        [
          Weakness.human_attribute_name('audit_recommendations'),
          weakness.audit_recommendations
        ],
        [
          Weakness.human_attribute_name('answer'),
          weakness.answer
        ],
        [
          ConclusionReview.human_attribute_name('conclusion'),
          weakness.review.conclusion_final_review.conclusion
        ],
        [
          ConclusionReview.human_attribute_name('evolution'),
          weakness.review.conclusion_final_review.evolution
        ],
        [
          I18n.t('follow_up_committee_report.weaknesses_heatmap.process_owner'),
          weakness.user_manager
        ],
        [
          I18n.t('follow_up_committee_report.weaknesses_heatmap.user_root'),
          weakness.user_root
        ]
      ].compact
    end

    def filter_weaknesses_heatmap weaknesses
      if params[:weaknesses_heatmap][:user_id].present?
        user = User.where(id: params[:weaknesses_heatmap][:user_id]).take!

        @filters << "<b>#{User.model_name.human count: 1}</b> = \"#{user.full_name}\""

        weaknesses.
          references(:finding_user_assignments).
          joins(:finding_user_assignments).
          where FindingUserAssignment.table_name => {
            user_id: user.self_and_descendants.map(&:id), process_owner: true
          }
      else
        weaknesses
      end
    end

    def filter_weaknesses_heatmap_by_risk weaknesses
      risk = Array(params[:weaknesses_heatmap][:risk]).reject(&:blank?).map &:to_i

      if risk.present?
        risk_texts = risk.map do |r|
          t "risk_types.#{Weakness.risks.invert[r]}"
        end

        @filters << "<b>#{Finding.human_attribute_name('risk')}</b> = \"#{risk_texts.to_sentence}\""

        weaknesses.by_risk risk
      else
        weaknesses
      end
    end

    def filter_weaknesses_heatmap_by_status weaknesses
      states               = Array(params[:weaknesses_heatmap][:finding_status]).reject(&:blank?).map &:to_i
      not_muted_states     = Finding::EXCLUDE_FROM_REPORTS_STATUS + [:implemented_audited]
      mute_state_filter_on = Finding::STATUS.except(*not_muted_states).values

      if states.present?
        unless states.sort == mute_state_filter_on.sort
          state_text = states.map do |s|
            t "findings.state.#{Finding::STATUS.invert[s]}"
          end

          @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text.to_sentence}\""
        end

        weaknesses.where state: states
      else
        weaknesses
      end
    end

    def filter_weaknesses_heatmap_by_title weaknesses
      if params[:weaknesses_heatmap][:finding_title].present?
        title = params[:weaknesses_heatmap][:finding_title]

        @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{title}\""

        weaknesses.with_title title
      else
        weaknesses
      end
    end

    def filter_weaknesses_heatmap_by_business_unit_type weaknesses
      business_unit_types = Array(params[:weaknesses_heatmap][:business_unit_type]).reject(&:blank?)

      if business_unit_types.present?
        selected_business_units = BusinessUnitType.list.where id: business_unit_types

        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_units.pluck('name').to_sentence}\""

        weaknesses.by_business_unit_type selected_business_units.ids
      else
        weaknesses
      end
    end

    def render_paginated_weaknesses
      @weaknesses = @weaknesses.page params[:page]
    end
end
