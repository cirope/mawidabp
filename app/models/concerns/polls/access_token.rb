module Polls::AccessToken
  extend ActiveSupport::Concern

  included do
    before_save :generate_access_token, on: :create
  end

  private

    def generate_access_token
      begin
        self.access_token = SecureRandom.hex
      end while self.class.exists?(access_token: access_token)
    end
end
