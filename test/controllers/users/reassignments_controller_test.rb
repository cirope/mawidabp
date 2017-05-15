require 'test_helper'

class Users::ReassignmentsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  setup do
    login user: users(:administrator_second_user), prefix: organizations(:google).prefix
  end

  test 'user findings reassignment edit' do
    get :edit, params: { id: users(:audited_user).user }

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
  end

  test 'user finding reassignment update' do
    login user: users(:administrator_user), prefix: organizations(:cirope).prefix

    assert_enqueued_emails 2 do
      assert_difference 'Notification.count' do
        patch :update, params: {
          id: users(:audited_user).user,
          other_id: users(:audited_second_user).id,
          with_findings: '1'
        }
      end
    end

    assert_redirected_to users_url
    assert_equal I18n.t('flash.users.reassignments.update.notice'), flash.notice
  end

  test 'user reviews reassignment edit' do
    get :edit, params: { id: users(:audited_user).user }

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
  end

  test 'user reviews reassignment update' do
    assert_enqueued_emails 2 do
      assert_difference 'Notification.count' do
        patch :update, params: {
          id: users(:audited_user).user,
          other_id: users(:audited_second_user).id,
          with_reviews: '1'
        }
      end
    end

    assert_redirected_to users_url
    assert_equal I18n.t('flash.users.reassignments.update.notice'), flash.notice
  end

  test 'user reassignment of nothing edit' do
    get :edit, params: { id: users(:audited_user).user }

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
  end

  test 'user reassignment of nothing' do
    assert_no_emails do
      assert_no_difference 'Notification.count' do
        patch :update, params: {
          id: users(:audited_user).user,
          other_id: users(:administrator_second_user).id
        }
      end
    end

    assert_redirected_to users_url
    assert_equal I18n.t('flash.users.reassignments.update.notice'), flash.notice
  end
end
