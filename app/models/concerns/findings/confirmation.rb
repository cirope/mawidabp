module Findings::Confirmation
  extend ActiveSupport::Concern

  def mark_as_unconfirmed!
    self.first_notification_date = Time.zone.today unless unconfirmed?
    self.state = Finding::STATUS[:unconfirmed] if notify?

    save validate: false
  rescue ActiveRecord::StaleObjectError
    review.reload
    save validate: false
  end

  def confirmed! user = nil
    if unconfirmed? || notify?
      update_column :state, Finding::STATUS[:confirmed]
      update_column :confirmation_date, Time.zone.today if confirmation_date.blank?

      mark_notifications_as_confirmed_by user if user
    end
  end

  private

    def mark_notifications_as_confirmed_by user
      notifications.not_confirmed.each do |notification|
        if notification.user.can_act_as_audited?
          notification.update!(
            status:            Notification::STATUS[:confirmed],
            confirmation_date: notification.confirmation_date || Time.zone.now,
            user_who_confirm:  user
          )
        end
      end
    end
end
