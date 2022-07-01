# frozen_string_literal: true

module Subsidiaries::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, :identity, presence: true
    validate :identity_only_numerics
  end

  private

    def identity_only_numerics
      if identity.present? && identity.scan(/\D/).present?
        errors.add(:identity, :only_numerics)
      end
    end
end
