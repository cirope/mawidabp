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
end
