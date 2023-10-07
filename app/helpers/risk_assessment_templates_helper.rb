module RiskAssessmentTemplatesHelper
  def risk_assessment_weights_ordered rat
    rat.risk_assessment_weights.ordered
  end
end
