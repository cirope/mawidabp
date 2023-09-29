module Findings::ByRiskMap
  extend ActiveSupport::Concern

  OPTIONS = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

  def risk_map_row options = {}
    [
      organization,
      organization_id,
      title,
      review.identification,
      (taggings_format if self.class.show_follow_up_timestamps?),
      control_objective_item_id,
      control_objective_item.control_objective_text,
      control_objective_item.relevance,
      control_objective_item.review.id,
      control_objective_item.design_score,
      control_objective_item.sustantive_score,
      control_objective_item.compliance_score,
      average_scores.to_f,
      id,
      description,
      review_code,
      risk,
      try(:risk_text) || '',
      state_text,
      state,
      origination_date,
      follow_up_date,
      updated_at,
      solution_date,
      priority,
      parent_id,
      repeated_of_id,
      'rescheduled',
      'rescheduled_description',
      'antiquity',
      pending_finding_to(options),
      new_finding_between_committee_dates(options),
      closed_finding_between_committee_dates(options),
      business_unit_type.external,
      business_unit.name,
      control_objective_item.best_practice.description,
      control_objective_item.best_practice.name,
      control_objective_item.best_practice.id,
      process_control.name,
      process_control.id
    ]
  end

  private

    def pending_finding_to options
      current_committee_date = options['current_committee_date'].to_date

      if current_committee_date.present?
        days                   = options['days'].to_i
        date_old               = current_committee_date - days

        origination_date < date_old ? '1' : '0'
      else
        '-'
      end
    end

    def new_finding_between_committee_dates options
      before_committee_date  = options['before_committee_date'].to_date
      current_committee_date = options['current_committee_date'].to_date

      if committee_dates_present? options
        if origination_date > before_committee_date && origination_date <= current_committee_date
          '1'
        else
          '0'
        end
      else
        '-'
      end
    end

    def closed_finding_between_committee_dates options
      before_committee_date  = options['before_committee_date'].to_date
      current_committee_date = options['current_committee_date'].to_date

      if committee_dates_present? options
        committee_to_solution_date = if solution_date
                                       solution_date > before_committee_date &&
                                         origination_date <= current_committee_date
                                     end

        if state == Finding::STATUS[:implemented_audited] && committee_to_solution_date
          '1'
        else
          '0'
        end
      else
        '-'
      end
    end

    def committee_dates_present? options
      before_committee_date  = options['before_committee_date'].to_date
      current_committee_date = options['current_committee_date'].to_date

      before_committee_date.present? && current_committee_date.present? ? true : false
    end

    def average_scores
      ( control_objective_item.design_score.to_i +
        control_objective_item.sustantive_score.to_i +
        control_objective_item.compliance_score.to_i ) / 3
    end

  module ClassMethods

    def by_risk_map options
      prefix_header_name = 'follow_up_committee_report.weaknesses_risk_map'

      csv_str = CSV.generate(**OPTIONS) do |csv|
        csv << risk_map_column_headers(prefix_header_name)
      end

      ChunkIterator.iterate all_with_inclusions do |cursor|
        csv_str += CSV.generate(**OPTIONS) do |csv|
          cursor.each { |f| csv << f.risk_map_row(options) }
        end
      end

      "\uFEFF#{csv_str}"
    end

    private

      def risk_map_column_headers prefix
        [
          I18n.t("#{prefix}.organization"),
          I18n.t("#{prefix}.organization_id"),
          I18n.t("#{prefix}.identification"),
          I18n.t("#{prefix}.review_identification"),
          (Tag.model_name.human(count: 0) if show_follow_up_timestamps?),
          I18n.t("#{prefix}.control_objective_item_id"),
          I18n.t("#{prefix}.control_objective_item_control_objective_text"),
          I18n.t("#{prefix}.control_objective_item_relevance"),
          I18n.t("#{prefix}.control_objective_item_review_id"),
          I18n.t("#{prefix}.control_objective_item_design_score"),
          I18n.t("#{prefix}.control_objective_item_sustantive_score"),
          I18n.t("#{prefix}.control_objective_item_compliance_score"),
          I18n.t("#{prefix}.average_score"),
          I18n.t("#{prefix}.finding_id"),
          I18n.t("#{prefix}.finding_description"),
          I18n.t("#{prefix}.finding_review_code"),
          I18n.t("#{prefix}.finding_risk"),
          I18n.t("#{prefix}.finding_risk_level"),
          I18n.t("#{prefix}.status"),
          I18n.t("#{prefix}.finding_state"),
          I18n.t("#{prefix}.finding_origination_date"),
          I18n.t("#{prefix}.finding_follow_up_date"),
          I18n.t("#{prefix}.finding_updated_at"),
          I18n.t("#{prefix}.finding_solution_date"),
          I18n.t("#{prefix}.finding_priority"),
          I18n.t("#{prefix}.finding_parent_id"),
          I18n.t("#{prefix}.finding_repeated_of_id"),
          I18n.t("#{prefix}.finding_pending_rescheduling"),
          I18n.t("#{prefix}.finding_rescheduling_description"),
          I18n.t("#{prefix}.finding_antiquity"),
          I18n.t("#{prefix}.old_data"),
          I18n.t("#{prefix}.new_finding"),
          I18n.t("#{prefix}.closed_finding"),
          I18n.t("#{prefix}.business_unit_external"),
          I18n.t("#{prefix}.business_unit_name"),
          I18n.t("#{prefix}.best_practice_description"),
          I18n.t("#{prefix}.best_practice_name"),
          I18n.t("#{prefix}.best_practice_id"),
          I18n.t("#{prefix}.process_control_name"),
          I18n.t("#{prefix}.process_control_id")
        ]
      end
  end
end
