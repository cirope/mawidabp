require 'test_helper'

class ProcessControlsControllerTest < ActionController::TestCase
  setup do
    @process_control = process_controls :iso_27000_security_policy
    @best_practice   = @process_control.best_practice

    login
  end

  test 'should get new' do
    get :new, xhr: true, params: {
      best_practice_id: @best_practice
    }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, xhr: true, params: {
      best_practice_id: @best_practice,
      id: @process_control
    }
    assert_response :success
  end
end
