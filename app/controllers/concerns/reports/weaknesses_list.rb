module Reports::WeaknessesList
  extend ActiveSupport::Concern

  include Reports::PDF
  include Reports::Period

  def weaknesses_list
    init_weaknesses_list_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: weaknesses_list_csv, filename: @title.downcase
      end
    end
  end

  private

    def init_weaknesses_list_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.weaknesses_list_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_list])
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
        includes(:business_unit, :business_unit_type, review: [:plan_item, :conclusion_final_review])

      if params[:weaknesses_list]
        weaknesses = filter_weaknesses_list_by_risk weaknesses
        weaknesses = filter_weaknesses_list_by_status weaknesses
        weaknesses = filter_weaknesses_list_by_title weaknesses
        weaknesses = filter_weaknesses_list_by_compliance weaknesses
        weaknesses = filter_weaknesses_list_by_business_unit_type weaknesses
        weaknesses = filter_weaknesses_list_by_impact weaknesses
        weaknesses = filter_weaknesses_list_by_operational_risk weaknesses
        weaknesses = filter_weaknesses_list_by_internal_control_components weaknesses
        weaknesses = filter_weaknesses_list_by_tags weaknesses
        weaknesses = filter_weaknesses_list_by_repeated weaknesses
      end

      @weaknesses = weaknesses.reorder order
    end

    def weaknesses_list_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = ::CSV.generate(options) do |csv|
        csv << weaknesses_list_csv_headers

        weaknesses_list_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def filter_weaknesses_list_by_risk weaknesses
      risk = Array(params[:weaknesses_list][:risk]).reject(&:blank?)

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

    def filter_weaknesses_list_by_repeated weaknesses
      repeated = params[:weaknesses_list][:repeated]

      return weaknesses if repeated.blank?

      repeated = repeated == 'true'

      @filters << "<b>#{t 'findings.state.repeated'}</b>: #{t("label.#{repeated ? 'yes' : 'no'}")}"

      repeated ? weaknesses.with_repeated : weaknesses.without_repeated
    end

    def filter_weaknesses_list_by_status weaknesses
      states               = Array(params[:weaknesses_list][:finding_status]).reject(&:blank?)
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

    def filter_weaknesses_list_by_title weaknesses
      if params[:weaknesses_list][:finding_title].present?
        title = params[:weaknesses_list][:finding_title]

        @filters << "<b>#{Finding.human_attribute_name('title')}</b> = \"#{title}\""

        weaknesses.with_title title
      else
        weaknesses
      end
    end

    def filter_weaknesses_list_by_compliance weaknesses
      if params[:weaknesses_list][:compliance].present?
        compliance = params[:weaknesses_list][:compliance]

        @filters << "<b>#{Finding.human_attribute_name('compliance')}</b> = \"#{t "label.#{compliance}"}\""

        weaknesses.where compliance: compliance
      else
        weaknesses
      end
    end

    def filter_weaknesses_list_by_business_unit_type weaknesses
      business_unit_types = Array(params[:weaknesses_list][:business_unit_type]).reject(&:blank?)

      if business_unit_types.present?
        selected_business_units = BusinessUnitType.list.where id: business_unit_types

        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = \"#{selected_business_units.pluck('name').to_sentence}\""

        weaknesses.by_business_unit_type selected_business_units.ids
      else
        weaknesses
      end
    end

    def filter_weaknesses_list_by_impact weaknesses
      impact = Array(params[:weaknesses_list][:impact]).reject(&:blank?)

      if impact.present?
        @filters << "<b>#{Weakness.human_attribute_name('impact')}</b> = \"#{impact.to_sentence}\""

        weaknesses.by_impact impact
      else
        weaknesses
      end
    end

    def filter_weaknesses_list_by_operational_risk weaknesses
      operational_risk = Array(params[:weaknesses_list][:operational_risk]).reject(&:blank?)

      if operational_risk.present?
        @filters << "<b>#{Weakness.human_attribute_name('operational_risk')}</b> = \"#{operational_risk.to_sentence}\""

        weaknesses.by_operational_risk operational_risk
      else
        weaknesses
      end
    end

    def filter_weaknesses_list_by_internal_control_components weaknesses
      internal_control_components = Array(params[:weaknesses_list][:internal_control_components]).reject(&:blank?)

      if internal_control_components.present?
        @filters << "<b>#{Weakness.human_attribute_name('internal_control_components')}</b> = \"#{internal_control_components.to_sentence}\""

        weaknesses.by_internal_control_components internal_control_components
      else
        weaknesses
      end
    end

    def filter_weaknesses_list_by_tags weaknesses
      weaknesses = filter_weaknesses_list_by_control_objective_tags weaknesses
      weaknesses = filter_weaknesses_list_by_weakness_tags weaknesses

      filter_weaknesses_list_by_review_tags weaknesses
    end

    def filter_weaknesses_list_by_control_objective_tags weaknesses
      tags = params[:weaknesses_list][:control_objective_tags].to_s.split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_list.control_objective_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_control_objective_tags tags
      else
        weaknesses
      end
    end

    def filter_weaknesses_list_by_weakness_tags weaknesses
      tags = params[:weaknesses_list][:weakness_tags].to_s.split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_list.weakness_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_wilcard_tags tags
      else
        weaknesses
      end
    end

    def filter_weaknesses_list_by_review_tags weaknesses
      tags = params[:weaknesses_list][:review_tags].to_s.split(
        SPLIT_AND_TERMS_REGEXP
      ).uniq.map(&:strip).reject(&:blank?)

      if tags.any?
        @filters << "<b>#{t 'follow_up_committee_report.weaknesses_list.review_tags'}</b> = \"#{tags.to_sentence}\""

        weaknesses.by_review_tags tags
      else
        weaknesses
      end
    end

    def weaknesses_list_csv_headers
      [
        BestPractice.model_name.human,
        ProcessControl.model_name.human,
        PlanItem.human_attribute_name('project'),
        Review.model_name.human,
        ConclusionFinalReview.human_attribute_name('issue_date'),
        ConclusionFinalReview.human_attribute_name('conclusion'),
        Weakness.human_attribute_name('risk'),
        Weakness.human_attribute_name('title'),
        Weakness.human_attribute_name('description'),
        Weakness.human_attribute_name('answer'),
        Weakness.human_attribute_name('state')
      ]
    end

    def weaknesses_list_csv_data_rows
      @weaknesses.map do |weakness|
        [
          weakness.control_objective_item.best_practice.name,
          weakness.control_objective_item.process_control.name,
          weakness.review.plan_item.project,
          weakness.review.identification,
          l(weakness.review.conclusion_final_review.issue_date),
          weakness.review.conclusion_final_review.conclusion,
          weakness.risk_text,
          weakness.title,
          weakness.description,
          weakness.answer,
          weakness.state_text
        ]
      end
    end
end
