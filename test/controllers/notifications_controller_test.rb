require 'test_helper'

# Pruebas para el controlador de notificaciones
class NotificationsControllerTest < ActionController::TestCase
  fixtures :notifications

  setup do
    login
  end

  test 'list notifications' do
    get :index
    assert_response :success
    assert_not_nil assigns(:notifications)
    assert_template 'notifications/index'
  end

  test 'show notification' do
    get :show, :id => notifications(
      :administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed).to_param
    assert_response :success
    assert_not_nil assigns(:notification)
    assert_template 'notifications/show'
  end

  test 'edit notification' do
    get :edit, :id => notifications(
      :administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed).to_param
    assert_response :success
    assert_not_nil assigns(:notification)
    assert_template 'notifications/edit'
  end

  test 'update notification' do
    assert_no_difference 'User.count' do
      patch :update, {
        :id => notifications(
          :administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed).to_param,
        :notification => {
          :notes => 'Updated notes'
        }
      }
    end

    assert_redirected_to notifications_url
    assert_not_nil assigns(:notification)
    assert_equal 'Updated notes', assigns(:notification).notes
  end

  test 'confirm' do
    notification_id = notifications(
      :bare_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed).id
    notification = Notification.find notification_id

    assert !notification.notified?
    get :confirm, :id => notification.confirmation_hash
    assert notification.reload.notified?
    assert notification.confirmed?
  end

  test 'reject' do
    notification_id = notifications(
      :bare_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed).id
    notification = Notification.find notification_id

    assert !notification.notified?
    get :confirm, :id => notification.confirmation_hash, :reject => 1
    assert notification.reload.notified?
    assert notification.rejected?
  end
end
