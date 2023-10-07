module RiskAssessmentTemplates::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :description, :formula, presence: true, pdf_encoding: true
    validates :formula, length: { maximum: 255 }, allow_blank: true
    validates :name, length: { maximum: 255 }, allow_blank: true, uniqueness: {
      case_sensitive: false, scope: :organization_id
    }
    validate :risk_assessment_weights_presence
    validate :validate_formula
  end

  private

    def risk_assessment_weights_presence
      unless risk_assessment_weights.reject(&:marked_for_destruction?).any?
        errors.add :risk_assessment_weights, :blank
      end
    end

    def validate_formula
      begin
        eval test_formula
      rescue Exception => exc
        errors.add :formula, :invalid
      end
    end

    def test_formula
      result = formula.dup

      values = risk_assessment_weights.reject(&:marked_for_destruction?).map do |raw|
        [raw.identifier, raw.risk_score_items.take&.value ]
      end

      values.to_h.each { |k,v| result.gsub! k, v.to_s }

      result
    end
end
