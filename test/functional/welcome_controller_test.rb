require 'test_helper'

# Pruebas para el controlador de bienvenida
class WelcomeControllerTest < ActionController::TestCase
  fixtures :users

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @public_actions = []
    @private_actions = [:index]
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    @private_actions.each do |action|
      get action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash[:alert]
    end

    @public_actions.each do |action|
      get action
      assert_response :success
    end
  end

  test 'show auditor welcome' do
    perform_auth
    get :index
    assert_response :success
    assert_select '#error_body', false
    assert_template 'welcome/auditor_index'
  end

  test 'show audited welcome' do
    perform_auth users(:audited_user)
    get :index
    assert_response :success
    assert_select '#error_body', false
    assert_template 'welcome/audited_index'
  end
end