require 'test_helper'

class Users::ReassignmentsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  setup do
    login user: users(:administrator_second), prefix: organizations(:google).prefix
  end

  test 'user findings reassignment edit' do
    get :edit, params: { id: users(:audited) }

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
  end

  test 'user finding reassignment update' do
    login user: users(:administrator), prefix: organizations(:cirope).prefix

    assert_enqueued_emails 2 do
      assert_difference 'Notification.count' do
        patch :update, params: {
          id: users(:audited),
          other_id: users(:audited_second).id,
          with_findings: '1'
        }
      end
    end

    assert_redirected_to users_url
    assert_equal I18n.t('flash.users.reassignments.update.notice'), flash.notice
  end

  test 'user reviews reassignment edit' do
    get :edit, params: { id: users(:audited) }

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
  end

  test 'user reviews reassignment update' do
    assert_enqueued_emails 2 do
      assert_difference 'Notification.count' do
        patch :update, params: {
          id: users(:audited),
          other_id: users(:audited_second).id,
          with_reviews: '1'
        }
      end
    end

    assert_redirected_to users_url
    assert_equal I18n.t('flash.users.reassignments.update.notice'), flash.notice
  end

  test 'user reassignment of nothing edit' do
    get :edit, params: { id: users(:audited) }

    assert_response :success
    assert_not_nil assigns(:user)
    assert_nil assigns(:other)
  end

  test 'user reassignment of nothing' do
    assert_no_emails do
      assert_no_difference 'Notification.count' do
        patch :update, params: {
          id: users(:audited),
          other_id: users(:administrator_second).id
        }
      end
    end

    assert_redirected_to users_url
    assert_equal I18n.t('flash.users.reassignments.update.notice'), flash.notice
  end
end
