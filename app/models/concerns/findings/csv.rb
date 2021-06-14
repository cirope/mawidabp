module Findings::Csv
  include ActionView::Helpers::TextHelper

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
      full_state_text,
      try(:risk_text) || '',
      respond_to?(:risk_text) ? priority_text : '',
      auditeds_as_process_owner.join('; '),
      audited_users.join('; '),
      auditor_users.join('; '),
      best_practice.name,
      process_control.name,
      control_objective_item.control_objective_text,
      origination_date_text,
      follow_up_date_text,
      solution_date_text,
      (implemented_at_text if self.class.show_follow_up_timestamps?),
      (closed_at_text if self.class.show_follow_up_timestamps?),
      rescheduled_text,
      reschedule_count.to_s,
      next_pending_task_date,
      listed_tasks,
      reiteration_info,
      audit_comments,
      audit_recommendations,
      answer,
      (last_commitment_date_text if self.class.show_follow_up_timestamps?),
      (finding_answers_text if self.class.show_follow_up_timestamps?),
      latest_answer_text
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
      I18n.t "label.#{rescheduled? ? 'yes' : 'no'}"
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

    def follow_up_date_text
      follow_up_date ? I18n.l(follow_up_date, format: :minimal) : '-'
    end

    def solution_date_text
      solution_date ? I18n.l(solution_date, format: :minimal) : '-'
    end

    def implemented_at_text
      implemented_at ? I18n.l(implemented_at, format: :minimal) : '-'
    end

    def closed_at_text
      closed_at ? I18n.l(closed_at, format: :minimal) : '-'
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

    def auditor_users
      users.select(&:auditor?).map &:full_name
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

      truncate(
        answers.reverse.join(LINE_BREAK_REPLACEMENT),
        length:   32767, # To go around the 32767 limit on some spreadsheets
        omission: "[#{I18n.t('messages.truncated', count: 32767)}]"
      )
    end

    def latest_answer_text
      answer = latest&.latest_answer || (latest.nil? && latest_answer)

      if answer
        date = I18n.l answer.created_at, format: :minimal

        "[#{date}] #{answer.user.full_name}: #{answer.answer}"
      else
        '-'
      end
    end

    def last_commitment_date_text
      commitment_date = finding_answers.map(&:commitment_date).compact.sort.last
      date            = if follow_up_date && commitment_date
                          follow_up_date <= commitment_date ? commitment_date : nil
                        elsif follow_up_date.blank?
                          commitment_date
                        end

      date ? I18n.l(date, format: :minimal) : ''
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
    def to_csv corporate: false
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**options) do |csv|
        csv << column_headers(corporate)

        all_with_inclusions.each { |f| csv << f.to_csv_a(corporate) }
      end

      "\uFEFF#{csv_str}"
    end

    def show_follow_up_timestamps?
      @show_follow_up_timestamps ||= begin
        setting = Current.organization.settings.find_by name: 'show_follow_up_timestamps'

        (setting ? setting.value : DEFAULT_SETTINGS[:show_follow_up_timestamps][:value]) != '0'
      end
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
          :latest_answer,
          latest: [:review, :latest_answer],
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

      def column_headers corporate
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
          Weakness.human_attribute_name('priority'),
          FindingUserAssignment.human_attribute_name('process_owner'),
          I18n.t('finding.audited', count: 0),
          I18n.t('finding.auditors', count: 0),
          BestPractice.model_name.human,
          ProcessControl.model_name.human,
          ControlObjectiveItem.human_attribute_name('control_objective_text'),
          Finding.human_attribute_name('origination_date'),
          Finding.human_attribute_name('follow_up_date'),
          Finding.human_attribute_name('solution_date'),
          (Finding.human_attribute_name('implemented_at') if show_follow_up_timestamps?),
          (Finding.human_attribute_name('closed_at') if show_follow_up_timestamps?),
          Finding.human_attribute_name('rescheduled'),
          Finding.human_attribute_name('reschedule_count'),
          I18n.t('finding.next_pending_task_date'),
          Task.model_name.human(count: 0),
          I18n.t('findings.state.repeated'),
          Finding.human_attribute_name('audit_comments'),
          Finding.human_attribute_name('audit_recommendations'),
          Finding.human_attribute_name('answer'),
          (FindingAnswer.human_attribute_name('commitment_date') if show_follow_up_timestamps?),
          (I18n.t('finding.finding_answers') if show_follow_up_timestamps?),
          (I18n.t('finding.latest_answer') if show_follow_up_timestamps?)
        ].compact
      end
  end
end
