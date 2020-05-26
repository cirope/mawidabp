require 'test_helper'

class PlanItemsControllerTest < ActionController::TestCase
  setup do
    @plan_item = plan_items :current_plan_item_1
    @plan      = @plan_item.plan

    login
  end

  test 'should get show' do
    get :new, xhr: true, params: {
      plan_id: @plan,
      id: @plan_item
    }
    assert_response :success
    assert_includes @response.content_type, 'text/javascript'
  end

  test 'should get new' do
    get :new, xhr: true, params: {
      plan_id: @plan
    }
    assert_response :success
    assert_includes @response.content_type, 'text/javascript'
  end

  test 'should get edit' do
    get :edit, xhr: true, params: {
      plan_id: @plan,
      id: @plan_item
    }
    assert_response :success
    assert_includes @response.content_type, 'text/javascript'
  end

  test 'should update' do
    assert_difference '@plan_item.control_objective_projects.count' do
      patch :update, xhr: true, params: {
        plan_id: @plan,
        id: @plan_item,
        plan_item: {
          control_objective_projects_attributes: [
            {
              control_objective_id: control_objectives(:management_dependency).id.to_s
            }
          ]
        }
      }
    end

    assert_response :success
    assert_includes @response.content_type, 'text/javascript'
  end
end
