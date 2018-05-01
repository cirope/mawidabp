module RiskAssessmentTemplates::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :description, presence: true, pdf_encoding: true
    validates :name, length: { maximum: 255 }, allow_blank: true, uniqueness: {
      case_sensitive: false, scope: :organization_id
    }
    validate :risk_assessment_weights_presence
  end

  private

    def risk_assessment_weights_presence
      unless risk_assessment_weights.reject(&:marked_for_destruction?).any?
        errors.add :risk_assessment_weights, :blank
      end
    end
end
