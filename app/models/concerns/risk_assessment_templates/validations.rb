module RiskAssessmentTemplates::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :description, :formula, presence: true, pdf_encoding: true
    validates :formula, length: { maximum: 255 }, allow_blank: true
    validates :name, length: { maximum: 255 }, allow_blank: true, uniqueness: {
      case_sensitive: false, scope: :organization_id
    }
    validate :risk_assessment_weights_presence
    validate :validate_expression
    validate :validate_heatmap
  end

  private

    def risk_assessment_weights_presence
      unless risk_assessment_weights.reject(&:marked_for_destruction?).any?
        errors.add :risk_assessment_weights, :blank
      end
    end

    def validate_heatmap
      raws = risk_assessment_weights.reject(&:marked_for_destruction?)

      if raws.select(&:heatmap).count > 2
        errors.add :risk_assessment_weights, :numericality, count: 2
      end
    end

    def validate_expression
      begin
        eval expression
      rescue Exception => exc
        errors.add :formula, :invalid
      end
    end

    def expression
      result = formula.dup.downcase

      values = risk_assessment_weights.reject(&:marked_for_destruction?).map do |raw|
        [raw.identifier, raw.risk_score_items.take&.value]
      end

      values.to_h.each { |k,v| result.gsub! k.strip.downcase, v.to_s }

      result
    end
end
