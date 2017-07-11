require 'test_helper'

class PlanItemsControllerTest < ActionController::TestCase
  setup do
    @plan_item = plan_items :current_plan_item_1
    @plan      = @plan_item.plan

    login
  end

  test 'should get new' do
    get :new, xhr: true, params: {
      plan_id: @plan
    }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, xhr: true, params: {
      plan_id: @plan,
      id: @plan_item
    }
    assert_response :success
  end
end
