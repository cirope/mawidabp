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
    @risk_weight.value = 10

    assert @risk_weight.invalid?
    assert_error @risk_weight, :value, :inclusion
  end
end
