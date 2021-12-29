module Findings::Csv
  include ActionView::Helpers::TextHelper

  extend ActiveSupport::Concern

  LINE_BREAK             = "\r\n"
  LINE_BREAK_REPLACEMENT = " | "
  OPTIONS                = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

  def to_csv_a corporate
    row = [
      review.identification,
      review.plan_item.project,
      (final_created_at_text if USE_SCOPE_CYCLE),
      issue_date_text,
      review.conclusion_final_review&.summary || '-',
      business_unit_type.name,
      business_unit.name,
      review_code,
      id,
      (taggings_format if self.class.show_follow_up_timestamps?),
      title,
      description,
      state_text,
      full_state_text,
      try(:risk_text) || '',
      (respond_to?(:risk_text) ? priority_text : '' unless USE_SCOPE_CYCLE),
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
      latest_answer_text,
      (try(:weakness_template)&.notes.to_s if USE_SCOPE_CYCLE),
      (try(:weakness_template)&.title.to_s if USE_SCOPE_CYCLE),
      (try(:weakness_template)&.reference.to_s if USE_SCOPE_CYCLE),
      (review.period if USE_SCOPE_CYCLE),
      (has_previous_review_label if USE_SCOPE_CYCLE),
      (commitment_support_plans_text if Finding.show_commitment_support?),
      (commitment_support_controls_text if Finding.show_commitment_support?),
      (commitment_support_reasons_text if Finding.show_commitment_support?),
      (commitment_date_required_level_text.to_s if Finding.show_commitment_support?),
      (supervisor_review if USE_SCOPE_CYCLE),
      (I18n.t "label.#{extension ? 'yes' : 'no'}" if USE_SCOPE_CYCLE),
      (follow_up_date_last_changed.to_s if USE_SCOPE_CYCLE)
    ].compact

    row.unshift organization.prefix if corporate

    row.map { |item| item.to_s.gsub(LINE_BREAK, LINE_BREAK_REPLACEMENT) }
  end

  private

    def supervisor_review
      supervisors = review.review_user_assignments.select do |rua|
        rua.supervisor?
      end

      supervisors.map do |supervisor|
        supervisor.user.full_name
      end.join ' - '
    end

    def has_previous_review_label
      if weakness_template_id
        previous_weakness = Finding.list.previous_weakness_by_template? review&.previous, weakness_template

        I18n.t "label.#{previous_weakness ? 'yes' : 'no'}"
      else
        I18n.t "label.no"
      end
    end

    def issue_date_text
      issue_date ? I18n.l(issue_date, format: :minimal) : '-'
    end

    def final_created_at_text
      review.conclusion_final_review ? I18n.l(review.conclusion_final_review.created_at, format: :minimal) : '-'
    end

    def date_text
      date = solution_date || follow_up_date

      date ? I18n.l(date, format: :minimal) : '-'
    end

    def taggings_format
      tags = taggings.map(&:tag)

      USE_SCOPE_CYCLE ? tags.join(' - ') : tags.to_sentence
    end

    def rescheduled_text
      I18n.t "label.#{rescheduled? ? 'yes' : 'no'}"
    end

    def reiteration_info
      if (ancestors = repeated_ancestors).any?
        "#{I18n.t('finding.repeated_ancestors')}: #{ancestors.to_sentence}"
      elsif (children = repeated_children).any?
        "#{I18n.t('finding.repeated_children')}: #{children.to_sentence}"
      else
        '-'
      end
    end

    def origination_date_text
      origination_date ? I18n.l(origination_date, format: :minimal) : '-'
    end

    def first_follow_up_date_text
      first_follow_up_date ? I18n.l(first_follow_up_date, format: :minimal) : '-'
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
      commitment_date = finding_answers.reverse.detect(&:commitment_date)&.commitment_date
      date            = if Finding.show_commitment_support?
                          commitment_date
                        elsif follow_up_date && commitment_date
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

    def commitment_support_plans_text
      plans = finding_answers.map do |fa|
        cs = fa.commitment_support

        if cs
          date = I18n.l fa.created_at, format: :minimal

          "[#{date}] #{fa.user.full_name}: #{cs.plan}"
        end
      end.compact

      truncate(
        plans.reverse.join(LINE_BREAK_REPLACEMENT),
        length:   32767, # To go around the 32767 limit on some spreadsheets
        omission: "[#{I18n.t('messages.truncated', count: 32767)}]"
      )
    end

    def commitment_support_controls_text
      controls = finding_answers.map do |fa|
        cs = fa.commitment_support

        if cs
          date = I18n.l fa.created_at, format: :minimal

          "[#{date}] #{fa.user.full_name}: #{cs.controls}"
        end
      end.compact

      truncate(
        controls.reverse.join(LINE_BREAK_REPLACEMENT),
        length:   32767, # To go around the 32767 limit on some spreadsheets
        omission: "[#{I18n.t('messages.truncated', count: 32767)}]"
      )
    end

    def commitment_support_reasons_text
      reasons = finding_answers.map do |fa|
        cs = fa.commitment_support

        if cs
          date         = I18n.l fa.created_at, format: :minimal
          endorsements = fa.endorsements.sort_by(&:updated_at).reverse.map do |e|
            status = I18n.t "findings.endorsements.status.#{e.status}"
            e_date = I18n.l e.updated_at, format: :minimal
            e_text = [e_date, status, e.reason].reject(&:blank?).join ' - '

            "#{e.user.full_name}: #{e_text}"
          end.to_sentence

          if endorsements.present?
            "[#{date}] (#{endorsements}) #{fa.user.full_name}: #{cs.reason}"
          else
            "[#{date}] #{fa.user.full_name}: #{cs.reason}"
          end
        end
      end.compact

      truncate(
        reasons.reverse.join(LINE_BREAK_REPLACEMENT),
        length:   32767, # To go around the 32767 limit on some spreadsheets
        omission: "[#{I18n.t('messages.truncated', count: 32767)}]"
      )
    end

  module ClassMethods
    def to_csv corporate: false
      csv_str = CSV.generate(**OPTIONS) do |csv|
        csv << column_headers(corporate)
      end

      ChunkIterator.iterate all_with_inclusions do |cursor|
        csv_str += CSV.generate(**OPTIONS) do |csv|
          cursor.each { |f| csv << f.to_csv_a(corporate) }
        end
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
          latest_answer: :user,
          latest: [:review, latest_answer: :user],
          finding_answers: [:user, :commitment_support, endorsements: :user],
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
          (I18n.t('attributes.created_at') if USE_SCOPE_CYCLE),
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
          I18n.t('finding.state_full'),
          Weakness.human_attribute_name('risk'),
          (Weakness.human_attribute_name('priority') unless USE_SCOPE_CYCLE),
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
          (I18n.t('finding.latest_answer') if show_follow_up_timestamps?),
          (WeaknessTemplate.human_attribute_name('notes') if USE_SCOPE_CYCLE),
          (WeaknessTemplate.human_attribute_name('title') if USE_SCOPE_CYCLE),
          (WeaknessTemplate.human_attribute_name('reference') if USE_SCOPE_CYCLE),
          (Plan.human_attribute_name('period_id') if USE_SCOPE_CYCLE),
          (I18n.t('finding.weakness_template_previous') if USE_SCOPE_CYCLE),
          (I18n.t('finding.commitment_support_plans') if Finding.show_commitment_support?),
          (I18n.t('finding.commitment_support_controls') if Finding.show_commitment_support?),
          (I18n.t('finding.commitment_support_reasons') if Finding.show_commitment_support?),
          (I18n.t('finding.commitment_date_required_level_title') if Finding.show_commitment_support?),
          (I18n.t('finding.supervisor') if USE_SCOPE_CYCLE),
          (Weakness.human_attribute_name('extension') if USE_SCOPE_CYCLE),
          (I18n.t('finding.follow_up_date_last_changed') if USE_SCOPE_CYCLE)
        ].compact
      end
  end
end
