require 'test_helper'

class TimeSummaryControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'should get index' do
    get :index

    assert_response :success
  end
end
