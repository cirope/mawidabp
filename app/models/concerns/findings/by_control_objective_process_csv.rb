module Findings::ByControlObjectiveProcessCsv
  extend ActiveSupport::Concern

  module ClassMethods
    def by_control_objective_process_csv options = {}
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**options) do |csv|
        csv << weaknesses_by_control_objective_process_csv_headers

        weaknesses_by_control_objective_process_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def weaknesses_by_control_objective_process_csv_headers
      [
        Review.model_name.human,
        PlanItem.human_attribute_name('project'),
        BusinessUnit.model_name.human,
        ProcessControl.model_name.human,
        ControlObjectiveItem.human_attribute_name('control_objective_text'),
        BusinessUnitType.model_name.human,
        I18n.t('follow_up_committee_report.weaknesses_by_control_objective_process.origination_year'),
        ConclusionFinalReview.human_attribute_name('conclusion'),
        Weakness.human_attribute_name('risk'),
        Weakness.human_attribute_name('title'),
        Weakness.human_attribute_name('description'),
        Weakness.human_attribute_name('current_situation'),
        Weakness.human_attribute_name('answer'),
        Weakness.human_attribute_name('state'),
        Weakness.human_attribute_name('follow_up_date'),
        Weakness.human_attribute_name('solution_date'),
        Weakness.human_attribute_name('id'),
        I18n.t('finding.audited', count: 0),
        I18n.t('finding.auditors', count: 0),
        Tag.model_name.human(count: 0),
        Weakness.human_attribute_name('compliance_observations')
      ].compact
    end

    def weaknesses_by_control_objective_process_csv_data_rows
      all.map do |weakness|
        [
          weakness.review.identification,
          weakness.review.plan_item.project,
          weakness.business_unit,
          weakness.control_objective_item.control_objective.process_control.name,
          weakness.control_objective_item.control_objective_text,
          weakness.business_unit.business_unit_type.name,
          (weakness.origination_date ? weakness.origination_date.year : '-'),
          weakness.review.conclusion_final_review.conclusion,
          weakness.risk_text,
          weakness.title,
          weakness.description,
          (weakness.current_situation ? weakness.current_situation : '-'),
          weakness.answer,
          weakness.state_text,
          (weakness.follow_up_date ? I18n.l(weakness.follow_up_date) : '-'),
          (weakness.solution_date ? I18n.l(weakness.solution_date) : '-'),
          weakness.id,
          weakness.users.select { |u|
            u.can_act_as_audited? && weakness.process_owners.exclude?(u)
          }.map(&:full_name).to_sentence,
          weakness.users.select(&:auditor?).map(&:full_name).to_sentence,
          weakness.review.tags.map(&:name).to_sentence,
          weakness.compliance_observations
        ].compact
      end
    end
  end
end
