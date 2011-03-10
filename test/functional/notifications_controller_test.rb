require 'test_helper'

# Pruebas para el controlador de notificaciones
class NotificationsControllerTest < ActionController::TestCase
  fixtures :notifications

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => notifications(
      :administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed).to_param}
    public_actions = [
      [:get, :confirm, id_param]
    ]
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :edit, id_param],
      [:put, :update, id_param],
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      flash.alert = nil
      send *action
      assert_not_equal I18n.t(:'message.must_be_authenticated'), flash.alert
    end
  end

  test 'list notifications' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:notifications)
    assert_select '#error_body', false
    assert_template 'notifications/index'
  end

  test 'show notification' do
    perform_auth
    get :show, :id => notifications(
      :administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed).to_param
    assert_response :success
    assert_not_nil assigns(:notification)
    assert_select '#error_body', false
    assert_template 'notifications/show'
  end

  test 'edit notification' do
    perform_auth
    get :edit, :id => notifications(
      :administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed).to_param
    assert_response :success
    assert_not_nil assigns(:notification)
    assert_select '#error_body', false
    assert_template 'notifications/edit'
  end

  test 'update notification' do
    assert_no_difference 'User.count' do
      perform_auth
      put :update, {
        :id => notifications(
          :administrator_user_bcra_A4609_security_management_responsible_dependency_weakness_being_implemented_confirmed).to_param,
        :notification => {
          :notes => 'Updated notes'
        }
      }
    end

    assert_redirected_to notifications_path
    assert_not_nil assigns(:notification)
    assert_equal 'Updated notes', assigns(:notification).notes
  end

  test 'confirm' do
    notification_id = notifications(
      :bare_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed).id
    notification = Notification.find notification_id

    assert !notification.notified?
    get :confirm, :id => notification.confirmation_hash
    assert_redirected_to :controller => :users, :action => :login
    assert_equal I18n.t(:'notification.confirmed'), flash.notice
    assert notification.reload.notified?
    assert notification.confirmed?
  end

  test 'reject' do
    notification_id = notifications(
      :bare_user_bcra_A4609_data_proccessing_impact_analisys_weakness_unconfirmed).id
    notification = Notification.find notification_id

    assert !notification.notified?
    assert_nil session[:go_to]
    get :confirm, :id => notification.confirmation_hash, :reject => 1
    assert_redirected_to :controller => :users, :action => :login
    assert_not_nil session[:go_to]
    assert_equal I18n.t(:'notification.rejected'), flash.notice
    assert notification.reload.notified?
    assert notification.rejected?
  end
end