module RiskScoreItems::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :value, presence: true
    validates :name, length: { maximum: 255 }, allow_blank: true, uniqueness: {
      case_sensitive: false, scope: :risk_assessment_weight
    }
    validates :value, allow_blank: true, numericality: {
      greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    }
  end
end
