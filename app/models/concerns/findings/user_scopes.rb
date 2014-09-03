module Findings::UserScopes
  extend ActiveSupport::Concern

  included do
    scope :all_for_reallocation, -> { where(state: Finding::PENDING_STATUS, final: false) }
    scope :for_notification, -> { where(state: Finding::STATUS[:notify], final: false) }
    scope :recently_notified, -> {
      where(
        state: Finding::STATUS[:unconfirmed],
        final: false,
        first_notification_date: Time.zone.today
      )
    }
  end
end
