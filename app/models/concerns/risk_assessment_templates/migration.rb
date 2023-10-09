module RiskAssessmentTemplates::Migration
  extend ActiveSupport::Concern

  included do
    RISK_TYPES = {
      none:        0,
      low:         1,
      medium_low:  2,
      medium:      3,
      medium_high: 4,
      high:        5
    }
  end

  def make_formula
    raws = risk_assessment_weights.ordered.pluck :identifier, :weight

    dividend = raws.map { |raw| raw.join(' * ') }.join(' + ')
    divisor  = raws.to_h.values.sum

    "(#{dividend}) / #{divisor}"
  end
end
