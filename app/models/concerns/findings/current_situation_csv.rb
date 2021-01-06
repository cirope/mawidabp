module Findings::CurrentSituationCsv
  extend ActiveSupport::Concern

  def show_current_situation?
    current_situation.present? && current_situation_verified
  end

  def weaknesses_current_situation_state_text current_weakness
    if id != current_weakness.id
      review           = current_weakness.review
      repeated_details = [
        current_weakness.review_code,
        review.identification,
        current_weakness.state_text
      ].join ' - '

      state_text = if review.has_final_review?
                     self.state_text
                   else
                     I18n.t 'follow_up_committee_report.weaknesses_current_situation.on_revision'
                   end

      "#{state_text} (#{repeated_details})"
    else
      self.state_text
    end
  end

  module ClassMethods
    def current_situation_csv options = {}
      csv_options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }
      benefits    = Benefit.list.order kind: :desc, created_at: :asc

      csv_str = CSV.generate(**csv_options) do |csv|
        csv << weaknesses_current_situation_csv_headers(benefits)

        weaknesses_current_situation_csv_data_rows(benefits).each do |row|
          csv << row
        end
      end

      "\uFEFF#{csv_str}"
    end

    private

      def weaknesses_current_situation_csv_headers benefits
        [
          BusinessUnit.model_name.human,
          PlanItem.human_attribute_name('project'),
          Review.model_name.human,
          BusinessUnitType.model_name.human,
          I18n.t('follow_up_committee_report.weaknesses_current_situation.origination_year'),
          ConclusionFinalReview.human_attribute_name('conclusion'),
          Weakness.human_attribute_name('risk'),
          Weakness.human_attribute_name('priority'),
          Weakness.human_attribute_name('title'),
          Weakness.human_attribute_name('description'),
          Weakness.human_attribute_name('answer'),
          Weakness.human_attribute_name('state'),
          Weakness.human_attribute_name('current_situation'),
          Weakness.human_attribute_name('follow_up_date'),
          Weakness.human_attribute_name('solution_date'),
          Finding.human_attribute_name('id'),
          I18n.t('finding.audited', count: 0),
          I18n.t('finding.auditors', count: 0),
          Tag.model_name.human(count: 0),
          Weakness.human_attribute_name('compliance_observations')
        ].concat benefits.pluck('name')
      end

      def weaknesses_current_situation_csv_data_rows benefits
        all.map do |weakness|
          current_weakness = weakness.current

          [
            weakness.business_unit.to_s,
            weakness.review.plan_item.project,
            weakness.review.identification,
            weakness.business_unit_type.to_s,
            (I18n.l weakness.origination_date, format: '%Y' if weakness.origination_date),
            weakness.review.conclusion_final_review.conclusion,
            current_weakness.risk_text,
            current_weakness.priority_text,
            current_weakness.title,
            current_weakness.description,
            current_weakness.answer,
            weakness.weaknesses_current_situation_state_text(current_weakness),
            (current_weakness.show_current_situation? ? current_weakness.current_situation : ''),
            (I18n.l current_weakness.follow_up_date if current_weakness.follow_up_date),
            (I18n.l weakness.solution_date if weakness.solution_date),
            weakness.id,
            weakness.users.select(&:can_act_as_audited?).map(&:full_name).join('; '),
            weakness.users.reject(&:can_act_as_audited?).map(&:full_name).join('; '),
            weakness.taggings.map(&:tag).join('; '),
            weakness.compliance_observations
          ].concat(benefits.map do |b|
            achievement = weakness.achievements.detect do |a|
              a.benefit_id == b.id
            end

            if achievement&.amount
              '%.2f' % achievement.amount
            else
              achievement&.comment
            end
          end)
        end
      end
  end
end
