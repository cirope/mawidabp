require 'test_helper'

class RiskCategoryTest < ActiveSupport::TestCase
  setup do
    @risk_category = risk_categories :risk_category
  end

  test 'create' do
    assert_difference 'RiskCategory.count' do
      @risk_category = RiskCategory.create(
        name: 'New name',
        risk_registry: @risk_category.risk_registry
      )
    end
  end

  test 'update' do
    assert @risk_category.update(name: 'Updated name'),
      @risk_category.errors.full_messages.join('; ')
    @risk_category.reload
    assert_equal 'Updated name', @risk_category.name
  end

  test 'destroy' do
    assert_difference 'RiskCategory.count', -1 do
      risk_categories(:risk_category).destroy
    end
  end

  test 'blank attributes' do
    @risk_category.name = ''

    assert @risk_category.invalid?
    assert_error @risk_category, :name, :blank
  end

  test 'attribute length' do
    @risk_category.name = 'abcde' * 52

    assert @risk_category.invalid?
    assert_error @risk_category, :name, :too_long, count: 255
  end

  test 'unique attributes' do
    risk_category = @risk_category.dup

    assert risk_category.invalid?
    assert_error risk_category, :name, :taken
  end
end
