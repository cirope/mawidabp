require 'test_helper'

class RiskAssessmentWeightTest < ActiveSupport::TestCase
  setup do
    @risk_assessment_weight = risk_assessment_weights :sox_404
  end

  test 'blank attributes' do
    @risk_assessment_weight.name = ''
    @risk_assessment_weight.description = ''
    @risk_assessment_weight.weight = ''

    assert @risk_assessment_weight.invalid?
    assert_error @risk_assessment_weight, :name, :blank
    assert_error @risk_assessment_weight, :description, :blank
    assert_error @risk_assessment_weight, :weight, :not_a_number
  end

  test 'unique attributes' do
    risk_assessment_weight = @risk_assessment_weight.dup

    assert risk_assessment_weight.invalid?
    assert_error risk_assessment_weight, :name, :taken
  end

  test 'attributes length' do
    @risk_assessment_weight.name = 'abcde' * 52

    assert @risk_assessment_weight.invalid?
    assert_error @risk_assessment_weight, :name, :too_long, count: 255
  end

  test 'attributes boundaries' do
    @risk_assessment_weight.weight = 0

    assert @risk_assessment_weight.invalid?
    assert_error @risk_assessment_weight, :weight, :greater_than, count: 0

    @risk_assessment_weight.weight = 101

    assert @risk_assessment_weight.invalid?
    assert_error @risk_assessment_weight, :weight, :less_than_or_equal_to, count: 100
  end

  test 'attributes encoding' do
    @risk_assessment_weight.name = "\n\t"
    @risk_assessment_weight.description = "\n\t"

    assert @risk_assessment_weight.invalid?
    assert_error @risk_assessment_weight, :name, :pdf_encoding
    assert_error @risk_assessment_weight, :description, :pdf_encoding
  end
end
