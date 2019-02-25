require 'test_helper'

class RiskAssessmentTemplateTest < ActiveSupport::TestCase
  setup do
    @risk_assessment_template = risk_assessment_templates :sox
  end

  test 'blank attributes' do
    @risk_assessment_template.name = ''
    @risk_assessment_template.description = ''

    @risk_assessment_template.risk_assessment_weights.destroy_all

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

  test 'destroy' do
    assert_no_difference 'RiskAssessmentTemplate.count' do
      @risk_assessment_template.destroy
    end

    @risk_assessment_template.risk_assessments.destroy_all

    assert_difference 'RiskAssessmentTemplate.count', -1 do
      @risk_assessment_template.destroy
    end
  end

  test 'clone from' do
    new_risk_assessment_template = RiskAssessmentTemplate.new

    new_risk_assessment_template.clone_from @risk_assessment_template

    all_weights_are_equal = new_risk_assessment_template.risk_assessment_weights.all? do |raw|
      exclusion_list = %w(id risk_assessment_template_id created_at updated_at)

      @risk_assessment_template.risk_assessment_weights.any? do |original_raw|
        raw.attributes.except(*exclusion_list) ==
          original_raw.attributes.except(*exclusion_list)
      end
    end

    assert new_risk_assessment_template.risk_assessment_weights.size > 0
    assert_equal @risk_assessment_template.risk_assessment_weights.size,
      new_risk_assessment_template.risk_assessment_weights.size
    assert all_weights_are_equal
  end
end
