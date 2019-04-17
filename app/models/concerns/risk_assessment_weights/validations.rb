module RiskAssessmentWeights::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :description, presence: true, pdf_encoding: true
    validates :name, length: { maximum: 255 }, allow_blank: true,
      uniqueness: {
        case_sensitive: false, scope: :risk_assessment_template_id
      }
    validates :weight, numericality: {
      only_integer: true, greater_than: 0, less_than_or_equal_to: 100
    }
  end
end
