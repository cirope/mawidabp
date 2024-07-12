module RiskAssessmentTemplatesHelper
  def risk_template_weights risk_template
    risk_template.risk_assessment_weights.new if risk_template.risk_assessment_weights.blank?

    risk_template.risk_assessment_weights
  end

  def risk_weights_score_items risk_weight
    risk_weight.risk_score_items.new if risk_weight.risk_score_items.blank?

    risk_weight.risk_score_items
  end
end
