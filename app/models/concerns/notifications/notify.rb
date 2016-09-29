module Notifications::Notify
  extend ActiveSupport::Concern

  def notify! confirmed = true
    new_status = confirmed ?
      Notification::STATUS[:confirmed] : Notification::STATUS[:rejected]

    Notification.transaction do
      update!(
        status:            new_status,
        user_who_confirm:  user,
        confirmation_date: Time.zone.now
      )

      confirm_findings new_status

      true
    end
  end

  private

    def confirm_findings new_status
      findings.each do |finding|
        finding.confirmed! user if user.can_act_as_audited?

        finding.notifications.uniq.each do |notification|
          if should_update? notification
            notification.update! status: new_status, user_who_confirm: user
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
