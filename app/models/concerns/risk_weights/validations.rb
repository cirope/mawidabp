module RiskWeights::Validations
  extend ActiveSupport::Concern

  included do
    delegate :final?, to: :risk_assessment_item

    validates :weight, presence: true
    validates :value, presence: true, if: :final?
    validates :value, inclusion: {
      in: RiskWeight.risks_values
    }, allow_blank: true
    validates :weight, numericality: {
      only_integer: true, greater_than: 0, less_than_or_equal_to: 100
    }, allow_blank: true
  end
end
