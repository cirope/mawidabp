module Users::Notifications
  extend ActiveSupport::Concern

  def send_welcome_email
    NotifierMailer.welcome_email(self).deliver_later unless send_notification_email.blank?
  end

  def send_notification_if_necesary
    if send_notification_email.present?
      reset_password Current.organization, notify: false

      NotifierMailer.welcome_email(self).deliver_later
    end
  end

  module ClassMethods
    def notify_new_findings
      if Time.zone.today.workday?
        users, findings = [], []

        all_with_findings_for_notification.each do |user|
          users << user

          findings |= user.findings.for_notification
        end

        Finding.transaction do
          raise ActiveRecord::Rollback unless findings.all? &:mark_as_unconfirmed
        end

        if CHECK_FINDING_EMAIL_REPLIES
          users.each do |user|
            user.findings.recently_notified.each do |finding|
              NotifierMailer.notify_new_finding(user, finding).deliver_later
            end
          end
        else
          users.each do |user|
            findings = user.findings.recently_notified

            NotifierMailer.notify_new_findings(user, findings).deliver_later
          end
        end
      end
    end
  end
end
