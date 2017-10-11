module Weaknesses::Validations
  extend ActiveSupport::Concern

  included do
    validates :risk, :priority, presence: true
    validates :audit_recommendations, presence: true, if: :notify?
    validates :progress, allow_nil: true, numericality: {
      only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    }
    validate :review_code_has_valid_prefix
  end

  private

    def review_code_has_valid_prefix
      regex = /\A#{prefix}\d+\Z/

      errors.add :review_code, :invalid unless review_code =~ regex
    end
end
