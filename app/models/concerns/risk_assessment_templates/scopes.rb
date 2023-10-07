module RiskAssessmentTemplates::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Current.organization&.id }
  end

  def eval_formula
    eval prepare_formula
  end

  private

    def prepare_formula
      result = formula.dup

      values = risk_assessment_weights.map do |raw|
        [raw.identifier, raw.risk_score_items.take&.value ]
      end

      values.to_h.each { |k,v| result.gsub! k, v.to_s }

      result
    end
end
