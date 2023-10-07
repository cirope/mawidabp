module RiskAssessmentWeights::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :description, :identifier, presence: true, pdf_encoding: true
    validates :name, :identifier, length: { maximum: 255 }, allow_blank: true,
      uniqueness: {
        case_sensitive: false, scope: :risk_assessment_template_id
      }
    validate :risk_score_items_presence
  end

  private

    def risk_score_items_presence
      unless risk_score_items.reject(&:marked_for_destruction?).any?
        errors.add :risk_score_items, :blank
      end
    end
end
