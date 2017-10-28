require 'test_helper'

class BestPractices::ControlObjectivesControllerTest < ActionController::TestCase
  setup do
    @control_objective = control_objectives :management_dependency
    @best_practice     = @control_objective.best_practice

    login
  end

  test 'should download' do
    get :download, params: {
      best_practice_id: @best_practice,
      id: @control_objective
    }

    assert_redirected_to @control_objective.support.url
  end
end
