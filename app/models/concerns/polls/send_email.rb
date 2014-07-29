module Polls::SendEmail
  extend ActiveSupport::Concern

  included do
    after_create :send_poll_email
  end

  private

    def send_poll_email
      NotifierMailer.delay.pending_poll_email(self)
    end
end
