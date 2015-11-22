module Findings::Csv
  extend ActiveSupport::Concern

  def to_a
    [
      review.identification,
      review.plan_item.project,
      review_code,
      title,
      state_text,
      respond_to?(:risk_text) ? risk_text : '',
      respond_to?(:risk_text) ? priority_text : '',
      audited.join('; '),
      control_objective_item.control_objective_text,
      origination_date_text,
      date_text,
      audit_comments,
      answer,
      finding_answers_text
    ]
  end

  private

    def date_text
      date = solution_date || follow_up_date

      I18n.l date, format: :minimal if date
    end

    def origination_date_text
      I18n.l origination_date, format: :minimal if origination_date
    end

    def audited
      process_owner_label = FindingUserAssignment.human_attribute_name 'process_owner'

      users.reload.select(&:can_act_as_audited?).map do |u|
        process_owners.include?(u) ? "#{u.full_name} (#{process_owner_label})" : u.full_name
      end
    end

    def finding_answers_text
      answers = finding_answers.map do |fa|
        date = I18n.l fa.created_at, format: :minimal

        "[#{date}] #{fa.user.full_name}: #{fa.answer}"
      end

      answers.join "\n"
    end

  module ClassMethods
    def to_csv completed = 'incomplete'
      CSV.generate(col_sep: ';') do |csv|
        csv << column_headers(completed)

        all.each { |f| csv << f.to_a }
      end
    end

    private

      def column_headers completed
        [
          Review.model_name.human,
          PlanItem.human_attribute_name('project'),
          Weakness.human_attribute_name('review_code'),
          Weakness.human_attribute_name('title'),
          Weakness.human_attribute_name('state'),
          Weakness.human_attribute_name('risk'),
          Weakness.human_attribute_name('priority'),
          I18n.t('finding.audited', count: 0),
          ControlObjectiveItem.human_attribute_name('control_objective_text'),
          Finding.human_attribute_name('origination_date'),
          date_label(completed),
          Finding.human_attribute_name('audit_comments'),
          Finding.human_attribute_name('answer'),
          I18n.t('finding.finding_answers')
        ]
      end

      def date_label completed
        column = completed == 'incomplete' ? 'follow_up_date' : 'solution_date'

        Finding.human_attribute_name column
      end
  end
end
