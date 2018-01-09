require 'test_helper'

class RiskAssessmentTemplateTest < ActiveSupport::TestCase
  setup do
    @risk_assessment_template = risk_assessment_templates :sox
  end

  test 'blank attributes' do
    @risk_assessment_template.name = ''
    @risk_assessment_template.description = ''

    @risk_assessment_template.risk_assessment_weights.clear

    assert @risk_assessment_template.invalid?
    assert_error @risk_assessment_template, :name, :blank
    assert_error @risk_assessment_template, :description, :blank
    assert_error @risk_assessment_template, :risk_assessment_weights, :blank
  end

  test 'unique attributes' do
    risk_assessment_template = @risk_assessment_template.dup

    assert risk_assessment_template.invalid?
    assert_error risk_assessment_template, :name, :taken
  end

  test 'attribute length' do
    @risk_assessment_template.name = 'abcde' * 52

    assert @risk_assessment_template.invalid?
    assert_error @risk_assessment_template, :name, :too_long, count: 255
  end

  test 'validates attributes encoding' do
    @risk_assessment_template.name = "\n\t"
    @risk_assessment_template.description = "\n\t"

    assert @risk_assessment_template.invalid?
    assert_error @risk_assessment_template, :name, :pdf_encoding
    assert_error @risk_assessment_template, :description, :pdf_encoding
  end
end
