# frozen_string_literal: true

require 'test_helper'

class ControlObjectiveAuditorTest < ActiveSupport::TestCase
  test 'invalid because user isnt auditor' do
    new_control_objective_auditor =
      ControlObjectiveAuditor.new user: users(:corporate),
                                  control_objective: control_objectives(:management_dependency)

    refute new_control_objective_auditor.valid?
    assert_error new_control_objective_auditor, :user_id, :invalid
  end
end
