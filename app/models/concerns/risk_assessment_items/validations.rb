module RiskAssessmentItems::Validations
  extend ActiveSupport::Concern

  included do
    delegate :final?, to: :risk_assessment

    validates :name, presence: true, pdf_encoding: true, length: { maximum: 255 }
    validates :business_unit, :risk, presence: true, if: :final?
    validates :order, presence: true
    validates :risk, numericality: {
      only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    }, allow_blank: true
  end
end
