module Users::Notifications
  extend ActiveSupport::Concern

  def send_welcome_email
    Notifier.welcome_email(self).deliver unless send_notification_email.blank?
  end

  def send_notification_if_necesary
    if send_notification_email.present?
      organization = Organization.find Organization.current_id

      reset_password! organization, false

      Notifier.welcome_email(self).deliver
    end
  end

  module ClassMethods
    def notify_new_findings
      unless [0, 6].include?(Date.today.wday)
        emails, findings = [], []

        all_with_findings_for_notification.each do |user|
          emails << Notifier.notify_new_findings(user)

          findings |= user.findings.for_notification
        end

        Finding.transaction do
          raise ActiveRecord::Rollback unless findings.all? &:mark_as_unconfirmed!

          emails.each &:deliver
        end
      end
    end
  end
end
