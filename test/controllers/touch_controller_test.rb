require 'test_helper'

class TouchControllerTest < ActionController::TestCase
  test 'should get index' do
    login

    post :create
    assert_response :success
  end
end
