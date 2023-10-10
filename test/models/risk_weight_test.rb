require 'test_helper'

class RiskWeightTest < ActiveSupport::TestCase
  setup do
    @risk_weight = risk_weights :sox_section_13_low_risk
  end

  test 'blank attributes' do
    @risk_weight.risk_assessment_weight = nil
    @risk_weight.identifier = nil

    assert @risk_weight.invalid?
    assert_error @risk_weight, :identifier, :blank
  end

  test 'blank attributes on final' do
    @risk_weight.risk_assessment_item.risk_assessment.update_columns status: 'final'

    @risk_weight.value = ''

    assert @risk_weight.invalid?
    assert_error @risk_weight, :value, :blank
  end

  test 'attribute inclusion' do
    @risk_weight.value = RiskWeight.risks_values.last.next

    assert @risk_weight.invalid?
    assert_error @risk_weight, :value, :inclusion
  end

  test 'should return default risk when dont have constant RISK_WEIGHTS' do
    skip if RISK_WEIGHTS.present?

    assert_equal RiskWeight::RISK_TYPES, RiskWeight.risks
  end

  test 'should return RISK_WEIGHTS when have constant' do
    skip unless RISK_WEIGHTS.present?

    assert_equal RISK_WEIGHTS, RiskWeight.risks
  end

  test 'should return default risk_values when dont have constant RISK_WEIGHTS' do
    skip if RISK_WEIGHTS.present?

    assert_equal RiskWeight::RISK_TYPES.values, RiskWeight.risks_values
  end

  test 'should return RISK_WEIGHTS values when have constant' do
    skip unless RISK_WEIGHTS.present?

    assert_equal RISK_WEIGHTS.values, RiskWeight.risks_values
  end
end
