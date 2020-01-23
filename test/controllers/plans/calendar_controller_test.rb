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

  test 'show project variant' do
    get :show, params: {
      id: @plan,
      project: true
    }
    assert_response :success
    assert_equal [:project], @request.variant
  end
end
