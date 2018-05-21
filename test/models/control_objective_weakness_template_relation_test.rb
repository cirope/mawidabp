require 'test_helper'

class ControlObjectiveWeaknessTemplateRelationTest < ActiveSupport::TestCase
  setup do
    @control_objective_weakness_template_relation =
      co_weakness_template_relations :impact_analysis_security
  end

  test 'blank attributes' do
    @control_objective_weakness_template_relation.control_objective = nil

    assert @control_objective_weakness_template_relation.invalid?
    assert_error @control_objective_weakness_template_relation, :control_objective, :blank
  end
end
