require 'test_helper'

class Users::ProfilesControllerTest < ActionController::TestCase
  setup do
    @user = users :administrator_user

    login
  end

  test 'edit' do
    get :edit, id: @user
    assert_response :success
    assert_not_nil assigns(:auth_user)
  end

  test 'update' do
    assert_no_difference 'User.count' do
      patch :update, id: @user, user: {
        name: 'Updated Name',
        last_name: 'Updated Last Name',
        email: 'updated@email.com',
        function: 'Updated function'
      }
    end

    assert_redirected_to edit_users_profile_url(@user)
    assert_equal 'Updated Name', @user.reload.name
  end
end
