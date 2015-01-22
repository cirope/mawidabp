module Findings::ScaffoldNotifications
  extend ActiveSupport::Concern

  module ClassMethods
    def notify_manager_if_necesary
      notify_managers if [0, 6].exclude? Time.zone.today.wday
    end

    def unanswered_and_stale factor
      includes(control_objective_item: { review: :period }).where(
        unanswered_and_stale_conditions,
        unanswered_and_stale_parameters(factor)
      ).references(:periods)
    end

    private

      def notify_managers
        Finding.transaction do
          n = 0

          while (findings = Finding.unanswered_and_stale(n += 1)).any?
            findings.each { |finding| finding.notify_for_level n }
          end
        end
      end

      def stale_parameters
        Organization.all_parameters 'finding_stale_confirmed_days'
      end

      def unanswered_and_stale_conditions
        [
          unanswered_and_stale_variable_conditions,
          unanswered_and_stale_fix_conditions
        ].join(' AND ')
      end

      def unanswered_and_stale_variable_conditions
        conditions = stale_parameters.each_with_index.map do |stale_parameter, i|
          [
            "first_notification_date < :stale_unanswered_date_#{i}",
            "#{Period.table_name}.organization_id = :organization_id_#{i}",
          ].join(' AND ')
        end

        "(#{conditions.map { |c| "(#{c})" }.join(' OR ')})"
      end

      def unanswered_and_stale_fix_conditions
        [
          'state = :state',
          'final = :false',
          'notification_level = :notification_level'
        ].join(' AND ')
      end

      def unanswered_and_stale_parameters factor
        parameters = {
          state: Finding::STATUS[:unanswered], false: false, notification_level: factor - 1
        }

        stale_parameters.each_with_index do |stale_parameter, i|
          stale_days = stale_parameter[:parameter].to_i
          parameters[:"stale_unanswered_date_#{i}"] = (stale_days + stale_days * factor).days.ago_in_business.to_date
          parameters[:"organization_id_#{i}"] = stale_parameter[:organization].id
        end

        parameters
      end
  end

  def users_for_scaffold_notification level = 1
    level_overflow = false
    users, highest_users = *initial_scaffold_users

    level.times do
      users |= highest_users = parents_for(highest_users)

      level_overflow ||= highest_users.empty?
    end

    level_overflow ? [] : users.uniq
  end

  def manager_users_for_level level = 1
    users, highest_users = *initial_scaffold_users

    level.times { highest_users = parents_for highest_users }

    highest_users.reject { |u| self.users.include? u }
  end

  def notification_date_for_level level = 1
    date_for_notification = first_notification_date.try(:dup) || Time.zone.today
    days_to_add = (stale_confirmed_days + stale_confirmed_days * level).next

    until days_to_add == 0
      date_for_notification += 1
      days_to_add -= 1 unless [0, 6].include? date_for_notification.wday
    end

    date_for_notification
  end

  def notify_for_level level
    level_users = users_for_scaffold_notification level
    has_audited_comments = finding_answers.reload.any? do |fa|
      fa.user.can_act_as_audited?
    end

    # No notificar si no hace falta
    if level_users.any? && !has_audited_comments
      NotifierMailer.unanswered_finding_to_manager_notification(self, level_users | users, level).deliver_later
    end

    update_column :notification_level, level_users.empty? ? -1 : level
  end

  private

    def initial_scaffold_users
      users = finding_user_assignments.map(&:user).select &:can_act_as_audited?
      highest_users = users.reject do |u|
        u.ancestors.any? { |p| users.include? p }
      end

      [users, highest_users]
    end

    def parents_for users
      users.map(&:parent).compact.uniq.select do |u|
        u.organizations.include? review.organization
      end
    end
end
