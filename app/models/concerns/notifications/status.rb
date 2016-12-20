module Notifications::Status
  extend ActiveSupport::Concern

  included do
    STATUS = {
      unconfirmed: 0,
      confirmed:   1,
      rejected:    2
    }

    scope :not_confirmed, -> { where status: STATUS[:unconfirmed] }

    STATUS.each do |name, value|
      define_method(:"#{name}?") { status == value }
    end
  end

  def notified?
    !unconfirmed?
  end

  def status_text
    I18n.t("notification.status_#{STATUS.invert[status]}")
  end

  def stale?
    unconfirmed? && created_at <= NOTIFICATIONS_STALE_DAYS.days.ago_in_business
  end
end
