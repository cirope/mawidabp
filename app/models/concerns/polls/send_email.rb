module Polls::SendEmail
  extend ActiveSupport::Concern

  included do
    after_commit :send_poll_email, on: :create
  end

  private

    def send_poll_email
      NotifierMailer.pending_poll_email(self).deliver_later
    end
end
