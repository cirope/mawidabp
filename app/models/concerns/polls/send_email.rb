module Polls::SendEmail
  extend ActiveSupport::Concern

  included do
    after_create :send_poll_email
  end

  private

    def send_poll_email
      Notifier.pending_poll_email(self).deliver
    end
end
