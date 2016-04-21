module Findings::Csv
  extend ActiveSupport::Concern

  LINE_BREAK = "\r\n"
  NEW_LINE   = "\n"

  def to_a
    [
      review.identification,
      review.plan_item.project,
      review_code,
      title,
      description.gsub(LINE_BREAK, NEW_LINE),
      state_text,
      respond_to?(:risk_text) ? risk_text : '',
      respond_to?(:risk_text) ? priority_text : '',
      auditeds_as_process_owner.join('; '),
      audited_users.join('; '),
      best_practice.name,
      process_control.name,
      control_objective_item.control_objective_text.gsub(LINE_BREAK, NEW_LINE),
      origination_date_text,
      date_text,
      audit_comments.gsub(LINE_BREAK, NEW_LINE),
      answer.gsub(LINE_BREAK, NEW_LINE),
      finding_answers_text.gsub(LINE_BREAK, NEW_LINE)
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

    def auditeds_as_process_owner
      process_owners.map &:full_name
    end

    def audited_users
      auditeds = users.reload.select do |u|
        u.can_act_as_audited? && process_owners.exclude?(u)
      end

      auditeds.map &:full_name
    end

    def process_control
      control_objective_item.control_objective.process_control
    end

    def best_practice
      control_objective_item.control_objective.process_control.best_practice
    end

    def finding_answers_text
      answers = finding_answers.map do |fa|
        date = I18n.l fa.created_at, format: :minimal

        "[#{date}] #{fa.user.full_name}: #{fa.answer}"
      end

      answers.join NEW_LINE
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
          Weakness.human_attribute_name('description'),
          Weakness.human_attribute_name('state'),
          Weakness.human_attribute_name('risk'),
          Weakness.human_attribute_name('priority'),
          FindingUserAssignment.human_attribute_name('process_owner'),
          I18n.t('finding.audited', count: 0),
          BestPractice.model_name.human,
          ProcessControl.model_name.human,
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
