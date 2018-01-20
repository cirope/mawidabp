require 'test_helper'

class RiskAssessmentItemTest < ActiveSupport::TestCase
  setup do
    @risk_assessment_item = risk_assessment_items :sox_section_13
  end

  test 'blank attributes' do
    @risk_assessment_item.order = nil
    @risk_assessment_item.name = ''
    @risk_assessment_item.risk = ''
    @risk_assessment_item.business_unit = nil

    assert @risk_assessment_item.invalid?
    assert_error @risk_assessment_item, :order, :blank
    assert_error @risk_assessment_item, :name, :blank
    assert_error @risk_assessment_item, :risk, :blank
    assert_error @risk_assessment_item, :business_unit, :blank
  end

  test 'attribute length' do
    @risk_assessment_item.name = 'abcde' * 52

    assert @risk_assessment_item.invalid?
    assert_error @risk_assessment_item, :name, :too_long, count: 255
  end

  test 'attribute boundaries' do
    @risk_assessment_item.risk = -1

    assert @risk_assessment_item.invalid?
    assert_error @risk_assessment_item, :risk, :greater_than_or_equal_to, count: 0

    @risk_assessment_item.risk = 101

    assert @risk_assessment_item.invalid?
    assert_error @risk_assessment_item, :risk, :less_than_or_equal_to, count: 100
  end

  test 'validates attributes encoding' do
    @risk_assessment_item.name = "\n\t"

    assert @risk_assessment_item.invalid?
    assert_error @risk_assessment_item, :name, :pdf_encoding
  end
end
