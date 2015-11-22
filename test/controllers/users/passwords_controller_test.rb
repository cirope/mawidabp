require 'test_helper'

class Users::PasswordsControllerTest < ActionController::TestCase
  def setup
    @request.host = "#{organizations(:cirope).prefix}.localhost.i"
  end

  test 'new password' do
    get :new
    assert_response :success
  end

  test 'create password reset' do
    user = users :blank_password_user
    original_hash = user.change_password_hash

    assert_difference 'ActionMailer::Base.deliveries.size' do
      post :create, user: { email: user.email }
    end

    assert_redirected_to login_url
    assert_not_nil user.reload.change_password_hash
    assert_not_equal original_hash, user.change_password_hash
    assert user.hash_changed > 1.minute.ago
  end

  test 'edit password' do
    login
    get :edit, { id: users(:blank_password_user) }
    assert_response :success
    assert_not_nil assigns(:auth_user)
  end

  test 'update password' do
    login
    user = users :administrator_user

    assert_difference 'OldPassword.count' do
      patch :update, {
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
    user = users :blank_password_user
    confirmation_hash = user.change_password_hash

    assert_difference 'OldPassword.count' do
      patch :update, {
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
    get :edit, { id: user, confirmation_hash: confirmation_hash }

    assert_redirected_to login_url
  end

  test 'change expired blank password' do
    user = users :expired_blank_password_user

    patch :update, {
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
