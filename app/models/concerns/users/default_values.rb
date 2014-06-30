module Users::DefaultValues
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      self.enable ||= false
      self.send_notification_email = true if send_notification_email.nil?
      self.password_changed = Time.zone.now
      self.language ||= 'es'

      if self.send_notification_email
        self.change_password_hash = SecureRandom.urlsafe_base64
        self.hash_changed         = Time.zone.now
      end
    end
end
