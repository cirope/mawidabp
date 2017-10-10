module Weaknesses::Validations
  extend ActiveSupport::Concern

  included do
    validates :risk, :priority, presence: true
    validates :audit_recommendations, presence: true, if: :notify?
    validate :review_code_has_valid_prefix
  end

  private

    def review_code_has_valid_prefix
      regex = /\A#{prefix}\d+\Z/

      errors.add :review_code, :invalid unless review_code =~ regex
    end
end
