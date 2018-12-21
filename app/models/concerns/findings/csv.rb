module Findings::CSV
  extend ActiveSupport::Concern

  LINE_BREAK             = "\r\n"
  LINE_BREAK_REPLACEMENT = " | "

  def to_csv_a corporate
    row = [
      review.identification,
      review.plan_item.project,
      issue_date_text,
      review.conclusion_final_review&.summary || '-',
      business_unit_type.name,
      business_unit.name,
      review_code,
      id,
      (taggings.map(&:tag).to_sentence if self.class.show_follow_up_timestamps?),
      title,
      description,
      state_text,
      try(:risk_text) || '',
      (respond_to?(:risk_text) ? priority_text : '' unless HIDE_WEAKNESS_PRIORITY),
      auditeds_as_process_owner.join('; '),
      audited_users.join('; '),
      best_practice.name,
      process_control.name,
      control_objective_item.control_objective_text,
      origination_date_text,
      date_text,
      rescheduled_text,
      next_pending_task_date,
      listed_tasks,
      reiteration_info,
      audit_comments,
      audit_recommendations,
      answer,
      (finding_answers_text if self.class.show_follow_up_timestamps?)
    ].compact

    row.unshift organization.prefix if corporate

    row.map { |item| item.to_s.gsub(LINE_BREAK, LINE_BREAK_REPLACEMENT) }
  end

  private

    def issue_date_text
      issue_date ? I18n.l(issue_date, format: :minimal) : '-'
    end

    def date_text
      date = solution_date || follow_up_date

      date ? I18n.l(date, format: :minimal) : '-'
    end

    def rescheduled_text
      if being_implemented? || awaiting?
        I18n.t "label.#{rescheduled? ? 'yes' : 'no'}"
      else
        '-'
      end
    end

    def reiteration_info
      if repeated_ancestors.any?
        "#{I18n.t('finding.repeated_ancestors')}: #{repeated_ancestors.to_sentence}"
      elsif repeated_children.any?
        "#{I18n.t('finding.repeated_children')}: #{repeated_children.to_sentence}"
      else
        '-'
      end
    end

    def origination_date_text
      origination_date ? I18n.l(origination_date, format: :minimal) : '-'
    end

    def auditeds_as_process_owner
      process_owners.map &:full_name
    end

    def audited_users
      process_owners = self.process_owners
      auditeds = users.select do |u|
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

      answers.reverse.join LINE_BREAK_REPLACEMENT
    end

    def next_pending_task_date
      task = tasks.detect { |t| !t.finished? }
      date = task&.due_on

      date ? I18n.l(date) : ''
    end

    def listed_tasks
      tasks.map(&:detailed_description).join(LINE_BREAK_REPLACEMENT)
    end

  module ClassMethods
    def to_csv completed: 'incomplete', corporate: false
      csv_str = ::CSV.generate(col_sep: ';', force_quotes: true) do |csv|
        csv << column_headers(completed, corporate)

        all_with_inclusions.each { |f| csv << f.to_csv_a(corporate) }
      end

      "\uFEFF#{csv_str}"
    end

    def show_follow_up_timestamps?
      setting = Current.organization.settings.reload.find_by name: 'show_follow_up_timestamps'

      (setting ? setting.value : DEFAULT_SETTINGS[:show_follow_up_timestamps][:value]) != '0'
    end

    private

      def all_with_inclusions
        preload *[
          :organization,
          :repeated_of,
          :repeated_in,
          :business_unit_type,
          :business_unit,
          :tasks,
          ({ tasks: :versions } if POSTGRESQL_ADAPTER),
          finding_answers: :user,
          finding_user_assignments: :user,
          finding_owner_assignments: :user,
          taggings: :tag,
          users: {
            organization_roles: :role
          },
          control_objective_item: {
            review: [:plan_item, :conclusion_final_review],
            control_objective: {
              process_control: :best_practice
            }
          }
        ].compact
      end

      def column_headers completed, corporate
        [
          (Organization.model_name.human if corporate),
          Review.model_name.human,
          PlanItem.human_attribute_name('project'),
          ConclusionFinalReview.human_attribute_name('issue_date'),
          ConclusionFinalReview.human_attribute_name('summary'),
          BusinessUnitType.model_name.human,
          BusinessUnit.model_name.human,
          Weakness.human_attribute_name('review_code'),
          Finding.human_attribute_name('id'),
          (Tag.model_name.human(count: 0) if show_follow_up_timestamps?),
          Weakness.human_attribute_name('title'),
          Weakness.human_attribute_name('description'),
          Weakness.human_attribute_name('state'),
          Weakness.human_attribute_name('risk'),
          (Weakness.human_attribute_name('priority') unless HIDE_WEAKNESS_PRIORITY),
          FindingUserAssignment.human_attribute_name('process_owner'),
          I18n.t('finding.audited', count: 0),
          BestPractice.model_name.human,
          ProcessControl.model_name.human,
          ControlObjectiveItem.human_attribute_name('control_objective_text'),
          Finding.human_attribute_name('origination_date'),
          date_label(completed),
          Finding.human_attribute_name('rescheduled'),
          I18n.t('finding.next_pending_task_date'),
          Task.model_name.human(count: 0),
          I18n.t('findings.state.repeated'),
          Finding.human_attribute_name('audit_comments'),
          Finding.human_attribute_name('audit_recommendations'),
          Finding.human_attribute_name('answer'),
          (I18n.t('finding.finding_answers') if show_follow_up_timestamps?)
        ].compact
      end

      def date_label completed
        column = completed == 'incomplete' ? 'follow_up_date' : 'solution_date'

        Finding.human_attribute_name column
      end
  end
end
