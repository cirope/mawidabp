require 'test_helper'

class RiskCategoryTest < ActiveSupport::TestCase
  setup do
    @risk_category = risk_categories :risk_category
  end

  test 'blank attributes' do
    @risk_category.name = ''

    assert @risk_category.invalid?
    assert_error @risk_category, :name, :blank
  end

  test 'unique attributes' do
    risk_category = @risk_category.dup

    assert risk_category.invalid?
    assert_error risk_category, :name, :taken
  end
end
