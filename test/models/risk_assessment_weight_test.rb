require 'test_helper'

class RiskAssessmentWeightTest < ActiveSupport::TestCase
  setup do
    @risk_assessment_weight = risk_assessment_weights :sox_404
  end

  test 'blank attributes' do
    @risk_assessment_weight.name = ''
    @risk_assessment_weight.description = ''
    @risk_assessment_weight.identifier = ''

    assert @risk_assessment_weight.invalid?
    assert_error @risk_assessment_weight, :name, :blank
    assert_error @risk_assessment_weight, :description, :blank
    assert_error @risk_assessment_weight, :identifier, :blank
  end

  test 'unique attributes' do
    risk_assessment_weight = @risk_assessment_weight.dup

    assert risk_assessment_weight.invalid?
    assert_error risk_assessment_weight, :name, :taken
    assert_error risk_assessment_weight, :identifier, :taken
  end

  test 'attributes length' do
    @risk_assessment_weight.name = 'abcde' * 52
    @risk_assessment_weight.identifier = 'abcde' * 52

    assert @risk_assessment_weight.invalid?
    assert_error @risk_assessment_weight, :name, :too_long, count: 255
    assert_error @risk_assessment_weight, :identifier, :too_long, count: 255
  end

  test 'attributes encoding' do
    @risk_assessment_weight.name = "\n\t"
    @risk_assessment_weight.description = "\n\t"
    @risk_assessment_weight.identifier = "\n\t"

    assert @risk_assessment_weight.invalid?
    assert_error @risk_assessment_weight, :name, :pdf_encoding
    assert_error @risk_assessment_weight, :description, :pdf_encoding
    assert_error @risk_assessment_weight, :identifier, :pdf_encoding
  end
end
