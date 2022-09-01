# frozen_string_literal: true

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

  test 'auto complete for control objective auditor' do
    get :auto_complete_for_control_objective_auditor,
        params: {
          q: 'corpo',
          control_objective_id: control_objectives(:management_dependency).id
        },
        format: :js,
        xhr: true

    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size # 0 because find user isnt auditor

    get :auto_complete_for_control_objective_auditor,
        params: {
          q: 'ditor',
          control_objective_id: control_objectives(:management_dependency).id
        },
        format: :js,
        xhr: true

    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size # 1 because find user is auditor

    get :auto_complete_for_control_objective_auditor,
        params: {
          q: 'ditor',
          control_objective_id: control_objectives(:organization_security_4_1).id
        },
        format: :js,
        xhr: true

    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size # 0 because find user is auditor in control objective
  end
end
