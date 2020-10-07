require 'test_helper'

class BestPracticeProjectTest < ActiveSupport::TestCase
  setup do
    @best_practice_project = best_practice_projects :current_plan_iso_27001
  end

  test 'blank attributes' do
    @best_practice_project.best_practice = nil
    @best_practice_project.plan_item = nil

    assert @best_practice_project.invalid?
    assert_error @best_practice_project, :best_practice, :blank
    assert_error @best_practice_project, :plan_item, :blank
  end
end
