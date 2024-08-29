require 'test_helper'

class RiskControlObjectiveTest < ActiveSupport::TestCase
  setup do
    @risk_control_objective = risk_control_objectives :risk_control_objective
  end

  test 'create' do
    assert_difference 'RiskControlObjective.count' do
      RiskControlObjective.create(
        control_objective: control_objectives(:impact_analysis),
        risk: @risk_control_objective.risk
      )
    end
  end

  test 'update' do
    control_objective = control_objectives :impact_analysis

    assert @risk_control_objective.update(control_objective: control_objective),
      @risk_control_objective.errors.full_messages.join('; ')
      @risk_control_objective.reload
    assert_equal control_objective, @risk_control_objective.control_objective
  end

  test 'destroy' do
    assert_difference 'RiskControlObjective.count', -1 do
      @risk_control_objective.destroy
    end
  end

  test 'blank attributes' do
    @risk_control_objective.risk_id = nil
    @risk_control_objective.control_objective_id = nil

    assert @risk_control_objective.invalid?
    assert_error @risk_control_objective, :risk, :blank
    assert_error @risk_control_objective, :control_objective, :blank
  end

  test 'unique attributes' do
    risk_control_objective = @risk_control_objective.dup

    assert risk_control_objective.invalid?
    assert_error risk_control_objective, :control_objective, :taken
  end
end
