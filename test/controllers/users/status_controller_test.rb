require 'test_helper'

class Users::StatusControllerTest < ActionController::TestCase
  setup do
    @user = users :administrator_user

    login
  end

  test 'show' do
    get :show, params: { id: @user }
    assert_response :success
    assert_not_nil assigns(:user)
    assert @request.variant.blank?
  end

  test 'show graph variant' do
    get :show, params: {
      id: @user,
      graph: true
    }
    assert_response :success
    assert_not_nil assigns(:user)
    assert_equal [:graph], @request.variant
  end
end
