require 'test_helper'

class Plans::CalendarControllerTest < ActionController::TestCase
  setup do
    @plan = plans :current_plan

    login
  end

  test 'should get show' do
    get :show, params: { id: @plan }
    assert_response :success
  end
end
