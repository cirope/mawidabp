module Findings::NotificationLevel
  extend ActiveSupport::Concern

  included do
    before_save :reset_notification_level, if: :reset_notification_level?
  end

  private

    def reset_notification_level
      self.notification_level = 0
    end

    def reset_notification_level?
      pending? && follow_up_date_changed?
    end
end
