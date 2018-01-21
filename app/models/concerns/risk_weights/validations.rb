module RiskWeights::Validations
  extend ActiveSupport::Concern

  included do
    validates :value, :weight, presence: true
    validates :value, inclusion: { in: RiskWeight.risks_values }
    validates :weight, numericality: {
      only_integer: true, greater_than: 0, less_than_or_equal_to: 100
    }
  end
end
