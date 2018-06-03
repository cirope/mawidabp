require 'test_helper'

# Pruebas para el controlador de notificaciones
class NotificationsControllerTest < ActionController::TestCase
  fixtures :notifications

  setup do
    login user: users(:audited)
  end

  test 'list notifications' do
    get :index
    assert_response :success
    assert_not_nil assigns(:notifications)
    assert_template 'notifications/index'
  end

  test 'show notification' do
    get :show, params: {
      id: notifications(:audited_unanswered_weakness_unconfirmed).to_param
    }
    assert_response :success
    assert_not_nil assigns(:notification)
    assert_template 'notifications/show'
  end

  test 'edit notification' do
    get :edit, params: {
      id: notifications(:audited_unanswered_weakness_unconfirmed).to_param
    }
    assert_response :success
    assert_not_nil assigns(:notification)
    assert_template 'notifications/edit'
  end

  test 'update notification' do
    assert_no_difference 'User.count' do
      patch :update, params: {
        id: notifications(:audited_unanswered_weakness_unconfirmed).to_param,
        notification: {
          notes: 'Updated notes'
        }
      }
    end

    assert_redirected_to notifications_url
    assert_not_nil assigns(:notification)
    assert_equal 'Updated notes', assigns(:notification).notes
  end

  test 'confirm' do
    notification_id = notifications(:audited_unanswered_weakness_unconfirmed).id
    notification = Notification.find notification_id

    assert !notification.notified?
    get :confirm, params: { id: notification.confirmation_hash }
    assert notification.reload.notified?
    assert notification.confirmed?
  end

  test 'reject' do
    notification_id = notifications(:audited_unanswered_weakness_unconfirmed).id
    notification = Notification.find notification_id

    assert !notification.notified?
    get :confirm, params: {
      id: notification.confirmation_hash,
      reject: 1
    }
    assert notification.reload.notified?
    assert notification.rejected?
  end
end
