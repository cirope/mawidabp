module RiskAssessmentWeights::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :description, :identifier, presence: true, pdf_encoding: true
    validates :name, length: { maximum: 255 }, allow_blank: true,
      uniqueness: {
        case_sensitive: false, scope: :risk_assessment_template_id
      }
  end
end
