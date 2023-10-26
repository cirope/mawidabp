require 'test_helper'

class RiskCategoryTest < ActiveSupport::TestCase
  setup do
    @risk_category = risk_categories :one
  end

  test 'blank attributes' do
    @risk_category.attr = ''

    assert @risk_category.invalid?
    assert_error @risk_category, :attr, :blank
  end

  test 'unique attributes' do
    risk_category = @risk_category.dup

    assert risk_category.invalid?
    assert_error risk_category, :attr, :taken
  end
end
