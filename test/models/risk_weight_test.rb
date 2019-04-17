require 'test_helper'

class RiskWeightTest < ActiveSupport::TestCase
  setup do
    @risk_weight = risk_weights :sox_section_13_low_risk
  end

  test 'blank attributes' do
    @risk_weight.weight = nil

    assert @risk_weight.invalid?
    assert_error @risk_weight, :weight, :blank
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

  test 'attributes boundaries' do
    @risk_weight.weight = 0

    assert @risk_weight.invalid?
    assert_error @risk_weight, :weight, :greater_than, count: 0

    @risk_weight.weight = 101

    assert @risk_weight.invalid?
    assert_error @risk_weight, :weight, :less_than_or_equal_to, count: 100
  end
end
