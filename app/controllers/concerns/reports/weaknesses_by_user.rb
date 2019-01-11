module Reports::WeaknessesByUser
  extend ActiveSupport::Concern

  include Reports::PDF
  include Reports::Period

  def weaknesses_by_user
    init_weaknesses_by_user_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: weaknesses_by_user_csv, filename: @title.downcase
      end
    end
  end

  def create_weaknesses_by_user
    init_weaknesses_by_user_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @weaknesses.any?
      @weaknesses.each do |weakness|
        by_user_pdf_items(weakness).each do |item|
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
        t("#{@controller}_committee_report.weaknesses_by_user.without_weaknesses"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_user')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_user')
  end

  private

    def init_weaknesses_by_user_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.weaknesses_by_user_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_by_user])
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
        list_with_final_review.
        by_issue_date('BETWEEN', @from_date, @to_date).
        includes(
          :business_unit,
          :business_unit_type,
          finding_answers: :user,
          review: [:plan_item, :conclusion_final_review]
        )

      if params[:weaknesses_by_user]
        weaknesses = filter_weaknesses_by_user weaknesses
        weaknesses = filter_weaknesses_by_user_by_risk weaknesses
        weaknesses = filter_weaknesses_by_user_by_status weaknesses
        weaknesses = filter_weaknesses_by_user_by_title weaknesses
        weaknesses = filter_weaknesses_by_user_by_business_unit_type weaknesses
      end

      @weaknesses = weaknesses.reorder order
    end

    def weaknesses_by_user_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = ::CSV.generate(options) do |csv|
        csv << weaknesses_by_user_csv_headers

        weaknesses_by_user_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def by_user_pdf_items weakness
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
          l(weakness.review.conclusion_final_review.issue_date)
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
          t("label.#{weakness.rescheduled ? 'yes' : 'no'}")
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
        ]
      ].compact
    end

    def show_by_user? weakness
      weakness.by_user.present? && weakness.by_user_verified
    end

    def filter_weaknesses_by_user weaknesses
      if params[:weaknesses_by_user][:user_id].present?
        user = User.where(id: params[:weaknesses_by_user][:user_id]).take!

        @filters << "<b>#{User.model_name.human count: 1}</b> = \"#{user.full_name}\""

        weaknesses.
          joins(:users).
          references(:user).
          where(User.table_name => { id: user.self_and_descendants.map(&:id) })
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_user_by_risk weaknesses
      risk = Array(params[:weaknesses_by_user][:risk]).reject(&:blank?)

      if risk.present?
        risk_texts = risk.map do |r|
          t "risk_types.#{Weakness.risks.invert[r.to_i]}"
        end

        @filters << "<b>#{Finding.human_attribute_name('risk')}</b> = \"#{risk_texts.to_sentence}\""

        weaknesses.by_risk risk
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_user_by_status weaknesses
      states               = Array(params[:weaknesses_by_user][:finding_status]).reject(&:blank?)
      not_muted_states     = Finding::EXCLUDE_FROM_REPORTS_STATUS + [:implemented_audited]
      mute_state_filter_on = Finding::STATUS.except(*not_muted_states).map do |k, v|
        v.to_s
      end

      if states.present?
        unless states.sort == mute_state_filter_on.sort
          state_text = states.map do |s|
            t "findings.state.#{Finding::STATUS.invert[s.to_i]}"
          end

          @filters << "<b>#{Finding.human_attribute_name('state')}</b> = \"#{state_text.to_sentence}\""
        end

        weaknesses.where state: states
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_user_by_title weaknesses
      if params[:weaknesses_by_user][:finding_title].present?
        title = params[:weaknesses_by_user][:finding_title]

        @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{title}\""

        weaknesses.with_title title
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_user_by_business_unit_type weaknesses
      business_unit_types = Array(params[:weaknesses_by_user][:business_unit_type]).reject(&:blank?)

      if business_unit_types.present?
        selected_business_units = BusinessUnitType.list.where id: business_unit_types

        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_units.pluck('name').to_sentence}\""

        weaknesses.by_business_unit_type selected_business_units.ids
      else
        weaknesses
      end
    end

    def weaknesses_by_user_csv_headers
      [
        Review.model_name.human,
        PlanItem.human_attribute_name('project'),
        ConclusionFinalReview.human_attribute_name('issue_date'),
        BusinessUnit.model_name.human,
        Weakness.human_attribute_name('review_code'),
        Weakness.human_attribute_name('title'),
        Weakness.human_attribute_name('description'),
        Weakness.human_attribute_name('state'),
        Weakness.human_attribute_name('risk'),
        t('finding.responsibles', count: 1),
        t('finding.audited', count: 0),
        Weakness.human_attribute_name('origination_date'),
        Weakness.human_attribute_name('follow_up_date'),
        Weakness.human_attribute_name('solution_date'),
        Weakness.human_attribute_name('rescheduled'),
        t('findings.state.repeated'),
        Weakness.human_attribute_name('audit_comments'),
        Weakness.human_attribute_name('audit_recommendations'),
        Weakness.human_attribute_name('answer'),
        (t('finding.finding_answers') if Weakness.show_follow_up_timestamps?)
      ].compact
    end

    def weaknesses_by_user_csv_data_rows
      @weaknesses.map do |weakness|
        [
          weakness.review.identification,
          weakness.review.plan_item.project,
          l(weakness.review.conclusion_final_review.issue_date),
          weakness.business_unit,
          weakness.review_code,
          weakness.title,
          weakness.description,
          weakness.state_text,
          weakness.risk_text,
          weakness.process_owners.map(&:full_name).to_sentence,
          weakness.users.select { |u|
            u.can_act_as_audited? && weakness.process_owners.exclude?(u)
          }.map(&:full_name).to_sentence,
          (weakness.origination_date ? l(weakness.origination_date) : '-'),
          (weakness.follow_up_date ? l(weakness.follow_up_date) : '-'),
          (weakness.solution_date ? l(weakness.solution_date) : '-'),
          t("label.#{weakness.rescheduled ? 'yes' : 'no'}"),
          t("label.#{weakness.repeated_of_id.present? ? 'yes' : 'no'}"),
          weakness.audit_comments,
          weakness.audit_recommendations,
          weakness.answer,
          (weakness.finding_answers.map { |fa|
            date = l fa.created_at, format: :minimal

            "[#{date}] #{fa.user.full_name}: #{fa.answer}"
          }.join("\n") if Weakness.show_follow_up_timestamps?)
        ].compact
      end
    end
end

