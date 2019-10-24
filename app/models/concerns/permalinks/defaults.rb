module Permalinks::Defaults
  extend ActiveSupport::Concern

  included do
    before_validation :set_defaults, on: :create
  end

  private

    def set_defaults
      self.token ||= SecureRandom.urlsafe_base64 32
    end
end
