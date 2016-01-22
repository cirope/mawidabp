require 'test_helper'

class BusinessUnitScoreTest < ActiveSupport::TestCase
  def setup
    @business_unit_score = business_unit_scores :iso_27000_security_organization_4_4_continuous_score
  end

  test 'blank attributes' do
    @business_unit_score.design_score     = nil
    @business_unit_score.compliance_score = nil
    @business_unit_score.sustantive_score = nil
    @business_unit_score.business_unit_id = nil

    assert @business_unit_score.invalid?
    assert_error @business_unit_score, :design_score,     :blank
    assert_error @business_unit_score, :compliance_score, :blank
    assert_error @business_unit_score, :sustantive_score, :blank
    assert_error @business_unit_score, :business_unit_id, :blank
  end

  test 'unique attributes' do
    business_unit_score = @business_unit_score.dup

    assert business_unit_score.invalid?
    assert_error business_unit_score, :business_unit_id, :taken
  end

  test 'effectiveness with only sustantive score' do
    high_qualification_value = ControlObjectiveItem.qualifications_values.max

    @business_unit_score.design_score = nil
    @business_unit_score.compliance_score = nil
    @business_unit_score.sustantive_score = high_qualification_value - 1

    expected = (high_qualification_value - 1) * 100.0 / high_qualification_value

    assert_equal expected, @business_unit_score.effectiveness
  end

  test 'effectiveness with all scores' do
    high_qualification_value = ControlObjectiveItem.qualifications_values.max

    @business_unit_score.design_score = high_qualification_value
    @business_unit_score.compliance_score = high_qualification_value - 1
    @business_unit_score.sustantive_score = high_qualification_value - 2

    expected = (high_qualification_value - 1) * 100.0 / high_qualification_value

    assert_equal expected, @business_unit_score.effectiveness
  end
end
