module Weaknesses::Validations
  extend ActiveSupport::Concern

  included do
    before_validation :clean_array_attributes

    validates :risk, :priority, presence: true
    validates :audit_recommendations, presence: true, if: :notify?
    validates :progress, allow_nil: true, numericality: {
      only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    }
    validate :review_code_has_valid_prefix

    validates :compliance, length: { maximum: 255 },
      allow_nil: true, allow_blank: true
    validates :compliance,
              :operational_risk,
              :impact,
              :internal_control_components,
              presence: true, if: :validate_extra_attributes?
  end

  private

    def review_code_has_valid_prefix
      regex = /\A#{prefix}\d+\Z/

      errors.add :review_code, :invalid unless review_code =~ regex
    end

    def validate_extra_attributes?
      SHOW_WEAKNESS_EXTRA_ATTRIBUTES
    end

    def clean_array_attributes
      self.impact = Array(impact).reject &:blank?
      self.internal_control_components =
        Array(internal_control_components).reject &:blank?
    end
end
