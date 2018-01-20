module RiskAssessmentItems::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true, pdf_encoding: true, length: { maximum: 255 }
    validates :order, :risk, :business_unit, presence: true
    validates :risk, numericality: {
      only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    }
  end
end
