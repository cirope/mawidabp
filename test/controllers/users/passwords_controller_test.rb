require 'test_helper'

class Users::PasswordsControllerTest < ActionController::TestCase
  setup do
    set_host_for_organization(organizations(:cirope).prefix)
  end

  test 'new password' do
    get :new
    assert_response :success
  end

  test 'create password reset' do
    user = users :blank_password
    original_hash = user.change_password_hash

    assert_difference 'ActionMailer::Base.deliveries.size' do
      post :create, params: {
        user: { email: user.email }
      }
    end

    assert_redirected_to login_url
    assert_not_nil user.reload.change_password_hash
    assert_not_equal original_hash, user.change_password_hash
    assert user.hash_changed > 1.minute.ago
  end

  test 'edit password' do
    login
    get :edit, params: { id: users(:blank_password) }
    assert_response :success
    assert_not_nil assigns(:auth_user)
  end

  test 'update password' do
    login
    user = users :administrator

    assert_difference 'OldPassword.count' do
      patch :update, params: {
        id: user,
        user: {
          password: 'new_password_123',
          password_confirmation: 'new_password_123'
        }
      }

      assert_redirected_to login_url
      assert_equal User.digest('new_password_123', user.salt), user.reload.password
    end
  end

  test 'change blank password' do
    user = users :blank_password
    confirmation_hash = user.change_password_hash

    assert_difference 'OldPassword.count' do
      patch :update, params: {
        id: user,
        confirmation_hash: confirmation_hash,
        user: {
          password: 'new_password_123',
          password_confirmation: 'new_password_123'
        }
      }
    end

    assert_redirected_to login_url
    assert_equal User.digest('new_password_123', user.salt), user.reload.password
    assert_not_nil user.last_access
    assert_nil user.change_password_hash
    assert_equal 0, user.failed_attempts

    # No se puede usar 2 veces el mismo hash
    get :edit, params: {
      id: user,
      confirmation_hash: confirmation_hash
    }

    assert_redirected_to login_url
  end

  test 'change expired blank password' do
    user = users :expired_blank_password

    patch :update, params: {
      id: user,
      confirmation_hash: user.change_password_hash,
      user: {
        password: 'new_password_123',
        password_confirmation: 'new_password_123'
      }
    }

    assert_redirected_to login_url
    assert_not_equal User.digest('new_password_123', user.salt), user.reload.password
  end
end
