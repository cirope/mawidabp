require 'test_helper'

class Plans::StatsControllerTest < ActionController::TestCase
  setup do
    @plan = plans :current_plan

    login
  end

  test 'should get show' do
    get :show, params: { id: @plan }
    assert_response :success
  end

  test 'should get show with until date' do
    month_before_end = @plan.period.end.advance(months: -1).at_end_of_month

    get :show, params: { id: @plan, until: month_before_end.to_s(:db) }
    assert_response :success
  end
end
