module Reports::WeaknessesByControlObjective
  extend ActiveSupport::Concern

  include Reports::PDF
  include Reports::Period

  def weaknesses_by_control_objective
    init_weaknesses_by_control_objective_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: weaknesses_by_control_objective_csv, filename: @title.downcase
      end
    end
  end

  def create_weaknesses_by_control_objective
    init_weaknesses_by_control_objective_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle]

    if @weaknesses.any?
      @weaknesses.each_with_index do |weakness, index|
        title = [
          "<b>#{index + 1}</b>",
          "<i>#{BusinessUnit.model_name.human}:</i>",
          weakness.business_unit
        ].join(' ')

        pdf.text title, size: PDF_FONT_SIZE, inline_format: true, align: :justify

        by_control_objective_pdf_items(weakness).each do |item|
          text = "<i>#{item.first}:</i> #{item.last.to_s.strip}"

          pdf.text text, size: PDF_FONT_SIZE, inline_format: true, align: :justify
        end

        pdf.move_down PDF_FONT_SIZE
      end
    else
      pdf.move_down PDF_FONT_SIZE
      pdf.text(
        t("#{@controller}_committee_report.weaknesses_by_control_objective.without_weaknesses"),
        style: :italic
      )
    end

    add_pdf_filters(pdf, @controller, @filters) if @filters.present?

    save_pdf(pdf, @controller, @from_date, @to_date, 'weaknesses_by_control_objective')

    redirect_to_pdf(@controller, @from_date, @to_date, 'weaknesses_by_control_objective')
  end

  private

    def init_weaknesses_by_control_objective_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.weaknesses_by_control_objective_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_by_control_objective])
      @filters = []
      @benefits = Benefit.list.order kind: :desc, created_at: :asc
      final = params[:final] == 'true'
      order = [
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
        "#{Weakness.quoted_table_name}.#{Weakness.qcn 'origination_date'} ASC",
        "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'conclusion_index'} DESC"
      ].map { |o| Arel.sql o }
      weaknesses = Weakness.
        with_repeated_status_for_report.
        finals(final).
        list_with_final_review.
        by_issue_date('BETWEEN', @from_date, @to_date).
        includes(:business_unit, :business_unit_type,
          achievements: [:benefit],
          review: [:plan_item, :conclusion_final_review]
        )

      if params[:weaknesses_by_control_objective]
        weaknesses = filter_weaknesses_by_control_objective_by_risk weaknesses
        weaknesses = filter_weaknesses_by_control_objective_by_status weaknesses
        weaknesses = filter_weaknesses_by_control_objective_by_title weaknesses
        weaknesses = filter_weaknesses_by_control_objective_by_compliance weaknesses
        weaknesses = filter_weaknesses_by_control_objective_by_business_unit_type weaknesses
        weaknesses = filter_weaknesses_by_control_objective_by_impact weaknesses
        weaknesses = filter_weaknesses_by_control_objective_by_operational_risk weaknesses
        weaknesses = filter_weaknesses_by_control_objective_by_internal_control_components weaknesses
        weaknesses = filter_weaknesses_by_control_objective_by_repeated weaknesses
      end

      @weaknesses = weaknesses.reorder order
    end

    def weaknesses_by_control_objective_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = ::CSV.generate(options) do |csv|
        csv << weaknesses_by_control_objective_csv_headers

        weaknesses_by_control_objective_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def by_control_objective_pdf_items weakness
      [
        [
          PlanItem.human_attribute_name('project'),
          weakness.review.plan_item.project
        ],
        [
          Review.model_name.human,
          weakness.review.identification
        ],
        [
          BusinessUnitType.model_name.human,
          weakness.business_unit_type
        ],
        [
          I18n.t('follow_up_committee_report.weaknesses_by_control_objective.origination_year'),
          (l(weakness.origination_date, format: '%Y') if weakness.origination_date)
        ],
        [
          Weakness.human_attribute_name('control_objective_item_id'),
          weakness.control_objective_item.control_objective_text
        ],
        [
          ControlObjectiveItem.human_attribute_name('auditor_comment'),
          weakness.control_objective_item.auditor_comment
        ]
      ].concat(
        if ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.include?(current_organization.prefix)
          [
            [
              ControlObjectiveItem.human_attribute_name('issues_count'),
              weakness.control_objective_item.issues_count
            ],
            [
              ControlObjectiveItem.human_attribute_name('alerts_count'),
              weakness.control_objective_item.alerts_count
            ]
          ]
        else
          []
        end
      ).compact
    end

    def show_by_control_objective? weakness
      weakness.by_control_objective.present? && weakness.by_control_objective_verified
    end

    def filter_weaknesses_by_control_objective_by_risk weaknesses
      risk = Array(params[:weaknesses_by_control_objective][:risk]).reject(&:blank?)

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

    def filter_weaknesses_by_control_objective_by_repeated weaknesses
      repeated = params[:weaknesses_by_control_objective][:repeated]

      return weaknesses if repeated.blank?

      repeated = repeated == 'true'

      @filters << "<b>#{t 'findings.state.repeated'}</b>: #{t("label.#{repeated ? 'yes' : 'no'}")}"

      repeated ? weaknesses.with_repeated : weaknesses.without_repeated
    end

    def filter_weaknesses_by_control_objective_by_status weaknesses
      states               = Array(params[:weaknesses_by_control_objective][:finding_status]).reject(&:blank?)
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

    def filter_weaknesses_by_control_objective_by_title weaknesses
      if params[:weaknesses_by_control_objective][:finding_title].present?
        title = params[:weaknesses_by_control_objective][:finding_title]

        @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{title}\""

        weaknesses.with_title title
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_control_objective_by_compliance weaknesses
      if params[:weaknesses_by_control_objective][:compliance].present?
        compliance = params[:weaknesses_by_control_objective][:compliance]

        @filters << "<b>#{Finding.human_attribute_name('compliance')}</b> = \"#{t "label.#{compliance}"}\""

        weaknesses.where compliance: compliance
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_control_objective_by_business_unit_type weaknesses
      business_unit_types = Array(params[:weaknesses_by_control_objective][:business_unit_type]).reject(&:blank?)

      if business_unit_types.present?
        selected_business_units = BusinessUnitType.list.where id: business_unit_types

        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_units.pluck('name').to_sentence}\""

        weaknesses.by_business_unit_type selected_business_units.ids
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_control_objective_by_impact weaknesses
      impact = Array(params[:weaknesses_by_control_objective][:impact]).reject(&:blank?)

      if impact.present?
        @filters << "<b>#{Weakness.human_attribute_name('impact')}</b> = \"#{impact.to_sentence}\""

        weaknesses.by_impact impact
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_control_objective_by_operational_risk weaknesses
      operational_risk = Array(params[:weaknesses_by_control_objective][:operational_risk]).reject(&:blank?)

      if operational_risk.present?
        @filters << "<b>#{Weakness.human_attribute_name('operational_risk')}</b> = \"#{operational_risk.to_sentence}\""

        weaknesses.by_operational_risk operational_risk
      else
        weaknesses
      end
    end

    def filter_weaknesses_by_control_objective_by_internal_control_components weaknesses
      internal_control_components = Array(params[:weaknesses_by_control_objective][:internal_control_components]).reject(&:blank?)

      if internal_control_components.present?
        @filters << "<b>#{Weakness.human_attribute_name('internal_control_components')}</b> = \"#{internal_control_components.to_sentence}\""

        weaknesses.by_internal_control_components internal_control_components
      else
        weaknesses
      end
    end

    def weaknesses_by_control_objective_csv_headers
      [
        BusinessUnit.model_name.human,
        PlanItem.human_attribute_name('project'),
        Review.model_name.human,
        BusinessUnitType.model_name.human,
        t('follow_up_committee_report.weaknesses_by_control_objective.origination_year'),
        Weakness.human_attribute_name('control_objective_item_id'),
        ControlObjectiveItem.human_attribute_name('auditor_comment')
      ].concat(
        if ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.include?(current_organization.prefix)
          [
            ControlObjectiveItem.human_attribute_name('issues_count'),
            ControlObjectiveItem.human_attribute_name('alerts_count')
          ]
        else
          []
        end
      )
    end

    def weaknesses_by_control_objective_csv_data_rows
      @weaknesses.map do |weakness|
        [
          weakness.business_unit.to_s,
          weakness.review.plan_item.project,
          weakness.review.identification,
          weakness.business_unit_type.to_s,
          (l weakness.origination_date, format: '%Y' if weakness.origination_date),
          weakness.control_objective_item.control_objective_text.to_s,
          weakness.control_objective_item.auditor_comment.to_s
        ].concat(
          if ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.include?(current_organization.prefix)
            [
              weakness.control_objective_item.issues_count.to_s,
              weakness.control_objective_item.alerts_count.to_s
            ]
          else
            []
          end
        )
      end
    end
end

