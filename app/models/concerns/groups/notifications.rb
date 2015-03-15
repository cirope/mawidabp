module Groups::Notifications
  extend ActiveSupport::Concern

  included do
    attr_accessor :send_notification_email

    after_save :send_notification_if_necesary
  end

  private

    def send_notification_if_necesary
      if send_notification_email.present?
        unless admin_hash
          self.send_notification_email = false

          self.update_attribute :admin_hash, SecureRandom.urlsafe_base64

          self.send_notification_email = true
        end

        NotifierMailer.delay.group_welcome_email(self)
      end
    end
end
