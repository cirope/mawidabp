require 'test_helper'

class Users::StatusControllerTest < ActionController::TestCase
  setup do
    @user = users :administrator

    login
  end

  test 'should get index' do
    get :index, session: { status_user_ids: [@user.id] }
    assert_redirected_to findings_url(completed: 'incomplete', user_ids: [@user.id])
    assert session[:status_user_ids].empty?
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

  test 'should add user to status via xhr' do
    post :create, params: { id: @user.id }, xhr: true, as: :js
    assert_response :success
    assert_equal @response.content_type, Mime[:js]
    assert_includes session[:status_user_ids], @user.id
  end

  test 'should delete user from status via xhr' do
    delete :destroy, params: {
      id: @user.id
    }, session: {
      status_user_ids: [@user.id]
    }, xhr: true, as: :js

    assert_response :success
    assert_equal @response.content_type, Mime[:js]
    assert session[:status_user_ids].exclude?(@user.id)
  end
end
