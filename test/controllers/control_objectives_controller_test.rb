require 'test_helper'

class ControlObjectivesControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'list control objectives' do
    get :index
    assert_response :success
    assert_not_nil assigns(:control_objectives)
    assert_template 'control_objectives/index'
  end

  test 'list control objectives with search' do
    login
    get :index, params: {
      search: {
        query: 'Management',
        columns: ['name']
      }
    }
    assert_response :success
    assert_not_nil assigns(:control_objectives)
    assert_equal 1, assigns(:control_objectives).count
    assert_template 'control_objectives/index'
  end

  test 'show control objective' do
    get :show, params: { id: control_objectives(:management_dependency).id }
    assert_response :success
    assert_not_nil assigns(:control_objective)
    assert_template 'control_objectives/show'
  end
end
