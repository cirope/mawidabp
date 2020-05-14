require 'test_helper'

class ControlObjectiveProjectTest < ActiveSupport::TestCase
  setup do
    @control_objective_project = control_objective_projects :current_plan_management_dependency
  end

  test 'blank attributes' do
    @control_objective_project.control_objective = nil
    @control_objective_project.plan_item = nil

    assert @control_objective_project.invalid?
    assert_error @control_objective_project, :control_objective, :blank
    assert_error @control_objective_project, :plan_item, :blank
  end
end
