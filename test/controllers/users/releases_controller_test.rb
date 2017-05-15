require 'test_helper'

class Users::ReleasesControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  setup do
    login
  end

  test 'user findings release edit' do
    get :edit, params: { id: users(:auditor_user).user }

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
  end

  test 'user findings release update' do
    assert_enqueued_emails 1 do
      patch :update, params: {
        id: users(:auditor_user).user,
        with_findings: '1'
      }
    end

    assert_redirected_to users_url
    assert_equal I18n.t('flash.users.releases.update.notice'), flash.notice
  end

  test 'user reviews release edit' do
    get :edit, params: { id: users(:auditor_user).user }

    assert_response :success
    assert_not_nil assigns(:user)
  end

  test 'user reviews release update' do
    assert_enqueued_emails 1 do
      patch :update, params: {
        id: users(:auditor_user).user,
        with_reviews: '1'
      }
    end

    assert_redirected_to users_url
    assert_equal I18n.t('flash.users.releases.update.notice'), flash.notice
  end

  test 'user release update of nothing' do
    assert_no_emails do
      post :update, params: { id: users(:auditor_user).user }
    end

    assert_redirected_to users_url
    assert_equal I18n.t('flash.users.releases.update.notice'), flash.notice
  end
end
