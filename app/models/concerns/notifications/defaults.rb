module Notifications::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      self.status            ||= Notification::STATUS[:unconfirmed]
      self.confirmation_hash ||= SecureRandom.urlsafe_base64
    end
end
