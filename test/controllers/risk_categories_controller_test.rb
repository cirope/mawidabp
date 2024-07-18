require 'test_helper'

class RiskCategoriesControllerTest < ActionController::TestCase
  setup do
    @risk_category = risk_categories :risk_category
    @risk_registry = @risk_category.risk_registry

    login
  end

  test 'should get new' do
    get :new, xhr: true, params: {
      risk_registry_id: @risk_registry
    }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, xhr: true, params: {
      risk_registry_id: @risk_registry,
      id: @risk_category
    }
    assert_response :success
  end
end
