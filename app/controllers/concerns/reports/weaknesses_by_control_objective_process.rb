module Reports::WeaknessesByControlObjectiveProcess
  extend ActiveSupport::Concern

  include Reports::FileResponder
  include Reports::Pdf
  include Reports::Period

  def weaknesses_by_control_objective_process
    init_weaknesses_by_control_objective_process_vars

    respond_to do |format|
      format.html
      format.csv  { render_weaknesses_by_control_objective_process_report_csv }
    end
  end

  def create_weaknesses_by_control_objective_process
    init_weaknesses_by_control_objective_process_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @weaknesses.any?
      @weaknesses.each do |weakness|
        by_control_objective_process_pdf_items(weakness).each do |item|
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
        t("#{@controller}_committee_report.weaknesses_by_control_objective_process.without_weaknesses"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_control_objective_process')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_control_objective_process')
  end

  private

    def init_weaknesses_by_control_objective_process_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.weaknesses_by_control_objective_process_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_by_control_objective_process])
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

      if params[:weaknesses_by_control_objective_process]
        weaknesses = filter_weaknesses_by_control_objective_process weaknesses
        weaknesses = filter_weaknesses_by_control_objective_process_by_risk weaknesses
        weaknesses = filter_weaknesses_by_control_objective_process_by_status weaknesses
        weaknesses = filter_weaknesses_by_control_objective_process_by_title weaknesses
        weaknesses = filter_weaknesses_by_control_objective_process_by_business_unit_type weaknesses
        weaknesses = filter_weaknesses_by_control_objective_process_by_tag weaknesses
      end

      @weaknesses = weaknesses.reorder order
    end

    def render_weaknesses_by_control_objective_process_report_csv
      render_or_send_by_mail(
        collection:  @weaknesses,
        filename:    "#{@title.downcase}.csv",
        method_name: :by_control_objective_process_csv
      )
    end

    def by_control_objective_process_pdf_items weakness
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
          BusinessUnit.model_name.human,
          weakness.business_unit
        ],
        [
          ProcessControl.model_name.human,
          weakness.control_objective_item.control_objective.process_control.name,
        ],
        [
          ControlObjectiveItem.human_attribute_name('control_objective_text'),
          weakness.control_objective_item.control_objective.process_control.name,
        ],
        [
          BusinessUnitType.model_name.human,
          weakness.business_unit.business_unit_type.name
        ],
        [
          t('follow_up_committee_report.weaknesses_by_control_objective_process.origination_year'),
          (weakness.origination_date ? weakness.origination_date.year : '-')
        ],
        [
          ConclusionFinalReview.human_attribute_name('conclusion'),
          weakness.review.conclusion_final_review.conclusion,
        ],
        [
          Weakness.human_attribute_name('risk'),
          weakness.risk_text
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
          Weakness.human_attribute_name('current_situation'),
          (weakness.current_situation ? weakness.current_situation : '-'),
        ],
        [
          Weakness.human_attribute_name('answer'),
          weakness.answer
        ],
        [
          Weakness.human_attribute_name('state'),
          weakness.state_text
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
          Weakness.human_attribute_name('id'),
          weakness.id,
        ],
        [
          t('finding.audited', count: 0),
          weakness.users.select { |u|
            u.can_act_as_audited? && weakness.process_owners.exclude?(u)
          }.map(&:full_name).to_sentence
        ],
        [
          t('finding.auditors', count: 0),
          weakness.users.select(&:auditor?).map(&:full_name).to_sentence
        ],
        [
          Tag.model_name.human(count: 0),
          weakness.review.tags.map(&:name).to_sentence,
        ],
        [
          Weakness.human_attribute_name('compliance_observations'),
          weakness.compliance_observations
        ]
      ].compact
    end

    def filter_weaknesses_by_control_objective_process weaknesses
      if params[:weaknesses_by_control_objective_process][:user_id].present?
        user = User.where(id: params[:weaknesses_by_control_objective_process][:user_id]).take!

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

    def filter_weaknesses_by_control_objective_process_by_risk weaknesses
      risk = Array(params[:weaknesses_by_control_objective_process][:risk]).reject(&:blank?).map &:to_i

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

    def filter_weaknesses_by_control_objective_process_by_status weaknesses
      states               = Array(params[:weaknesses_by_control_objective_process][:finding_status]).reject(&:blank?).map &:to_i
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

    def filter_weaknesses_by_control_objective_process_by_title weaknesses
      if params[:weaknesses_by_control_objective_process][:finding_title].present?
        title = params[:weaknesses_by_control_objective_process][:finding_title]

        @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{title}\""

        weaknesses.with_title title
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_control_objective_process_by_business_unit_type weaknesses
      business_unit_types = Array(params[:weaknesses_by_control_objective_process][:business_unit_type]).reject(&:blank?)

      if business_unit_types.present?
        selected_business_units = BusinessUnitType.list.where id: business_unit_types

        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_units.pluck('name').to_sentence}\""

        weaknesses.by_business_unit_type selected_business_units.ids
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_control_objective_process_by_tag weaknesses
      weaknesses = filter_weaknesses_control_objective_process_by_control_objective_tags weaknesses
      weaknesses = filter_weaknesses_control_objective_process_by_weakness_tags weaknesses

      filter_weaknesses_control_objective_process_by_review_tags weaknesses
    end

    def filter_weaknesses_control_objective_process_by_control_objective_tags weaknesses
      tags = params[:weaknesses_by_control_objective_process][:control_objective_tags].to_s.split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_control_objective_process.control_objective_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_control_objective_tags tags
      else
        weaknesses
      end
    end

    def filter_weaknesses_control_objective_process_by_weakness_tags weaknesses
      tags = params[:weaknesses_by_control_objective_process][:weakness_tags].to_s.split(
        SPLIT_OR_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_control_objective_process.weakness_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_wilcard_tags tags
      else
        weaknesses
      end
    end

    def filter_weaknesses_control_objective_process_by_review_tags weaknesses
      tags = params[:weaknesses_by_control_objective_process][:review_tags].to_s.split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_control_objective_process.review_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_review_tags tags
      else
        weaknesses
      end
    end
end
