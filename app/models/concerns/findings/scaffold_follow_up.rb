module Findings::ScaffoldFollowUp
  extend ActiveSupport::Concern

  included do
    scope :not_notified_today, -> {
      where.not(last_notification_date: Time.zone.today).or(
        where last_notification_date: nil
      )
    }
  end

  module ClassMethods
    def notify_expired_and_stale_follow_up
      if NOTIFY_EXPIRED_AND_STALE_FOLLOW_UP && Time.zone.today.workday?
        notify_expired_and_stale_findings
      end
    end

    def pending_expired_and_stale n
      follow_up_column = "#{quoted_table_name}.#{qcn 'follow_up_date'}"
      pending_statuses = [
        Finding::STATUS[:being_implemented],
        Finding::STATUS[:awaiting]
      ]

      Finding.
        not_notified_today.
        finals(false).
        where("#{follow_up_column} < ?", n.weeks.ago.to_date).
        where(
          state:              pending_statuses,
          notification_level: n - 1
        )
    end

    private

      def notify_expired_and_stale_findings
        Finding.transaction do
          deepest_level = User.deepest_level

          (1..deepest_level).each do |n|
            Finding.pending_expired_and_stale(n).find_each do |finding|
              finding.notify_expired_for_level n
            end
          end
        end
      end
  end

  def notify_expired_for_level level
    level_users     = users_for_scaffold_notification level
    commitment_date = last_commitment_date

    if level_users.any? && (commitment_date.blank? || commitment_date.past?)
      NotifierMailer.
        expired_finding_to_manager_notification(self, level_users | users, level).
        deliver_later

      update_columns notification_level:     level,
                     last_notification_date: Time.zone.today
    else
      update_column :notification_level, -1
    end
  end
end
