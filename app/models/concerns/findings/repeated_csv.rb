module Findings::RepeatedCsv
  extend ActiveSupport::Concern

  module ClassMethods
    def repeated_csv options = {}
      csv_options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**csv_options) do |csv|
        csv << weaknesses_repeated_csv_headers

        weaknesses_repeated_csv_data_rows.each do |row|
          csv << row
        end
      end

      "\uFEFF#{csv_str}"
    end

    private

      def weaknesses_repeated_csv_headers
        repeated_text = I18n.t 'findings.state.repeated'

        [
          "#{repeated_text} - #{Review.model_name.human}",
          PlanItem.human_attribute_name('project'),
          I18n.t('follow_up_committee_report.weaknesses_repeated.origination_year'),
          "#{repeated_text} - #{Weakness.human_attribute_name 'risk'}",
          "#{repeated_text} - #{Weakness.human_attribute_name('title')}",
          Weakness.human_attribute_name('description'),
          "#{repeated_text} - #{Weakness.human_attribute_name 'answer'}",
          Review.model_name.human,
          Weakness.human_attribute_name('risk'),
          Weakness.human_attribute_name('state'),
          Weakness.human_attribute_name('title'),
          Weakness.human_attribute_name('answer'),
          Weakness.human_attribute_name('follow_up_date')
        ]
      end

      def weaknesses_repeated_csv_data_rows
        all.map do |weakness|
          current_weakness = weakness.current

          [
            weakness.review.identification,
            weakness.review.plan_item.project,
            (I18n.l weakness.origination_date, format: '%Y' if weakness.origination_date),
            weakness.risk_text,
            weakness.title,
            weakness.description,
            weakness.answer,
            current_weakness.review.identification,
            current_weakness.risk_text,
            current_weakness.state_text,
            current_weakness.title,
            current_weakness.answer,
            (I18n.l current_weakness.follow_up_date if weakness.follow_up_date)
          ]
        end
      end
  end
end
