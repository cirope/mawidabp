require 'test_helper'

# Pruebas para el controlador de bienvenida
class WelcomeControllerTest < ActionController::TestCase
  fixtures :users

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    public_actions = []
    private_actions = [:index]

    private_actions.each do |action|
      get action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'show auditor welcome' do
    login
    get :index
    assert_response :success
    assert_template 'welcome/auditor_index'
  end

  test 'show audited welcome' do
    login user: users(:audited)
    get :index
    assert_response :success
    assert_template 'welcome/audited_index'
  end
end
