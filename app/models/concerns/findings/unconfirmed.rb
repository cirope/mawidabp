module Findings::Unconfirmed
  extend ActiveSupport::Concern

  included do
    scope :unconfirmed_for_notification, -> (days) {
      where(
        [
          'first_notification_date = :stale_unconfirmed_date',
          'state = :state',
          'final = :false'
        ].join(' AND '),
        {
          state: Finding::STATUS[:unconfirmed],
          false: false,
          stale_unconfirmed_date: days.business_days.ago.to_date
        }
      )
    }
  end

  module ClassMethods
    def notify_for_unconfirmed_for_notification_findings
      if Time.zone.today.workday?
        finding_days_for_next_notifications_parameters.each do |organization, value|
          Current.organization = organization
          Current.group        = organization.group
          days_array           = value.to_s.split(',').map { |v| v.strip.to_i }

          days_array.each do |days|
            Finding.transaction do
              findings = Finding.list.unconfirmed_for_notification(days)

              notify findings, days
            end
          end
        end
      end
    end

    private

    def notify findings, days
      users = findings.inject([]) do |u, finding|
        u | finding.users.select do |user|
          user.notifications.not_confirmed.any? { |n| n.findings.include?(finding) }
        end
      end

      users.each { |user| NotifierMailer.stale_notification(user, days).deliver_later }
    end

    def finding_days_for_next_notifications_parameters
      Organization.all_parameters('finding_days_for_next_notifications').map do |p|
        [p[:organization], p[:parameter]]
      end
    end
  end
end
