module Notifications::Notify
  extend ActiveSupport::Concern

  def notify! confirmed = true
    new_notification_attributes = {
      status:            Notification::STATUS[confirmed ? :confirmed : :rejected],
      user_who_confirm:  user,
      confirmation_date: Time.zone.now
    }

    Notification.transaction do
      update!          new_notification_attributes
      confirm_findings new_notification_attributes

      true
    end
  end

  private

    def confirm_findings new_notification_attributes
      findings.each do |finding|
        finding.confirmed! user if user.can_act_as_audited?

        finding.notifications.distinct.each do |notification|
          if should_update? notification
            notification.update! new_notification_attributes
          end
        end
      end
    rescue ActiveRecord::RecordInvalid
      raise ActiveRecord::Rollback
    end

    def should_update? notification
      notified? &&
        notification != self &&
        user.can_act_as_audited? &&
        !notification.user.can_act_as_audited?
    end
end
