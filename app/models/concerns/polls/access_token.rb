module Polls::AccessToken
  extend ActiveSupport::Concern

  included do
    before_create :generate_access_token
  end

  private

    def generate_access_token
      begin
        self.access_token = SecureRandom.hex
      end while self.class.unscoped.exists? access_token: access_token
    end
end
