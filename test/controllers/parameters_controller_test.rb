require 'test_helper'

# Pruebas para el controlador de parámetros
class ParametersControllerTest < ActionController::TestCase
  fixtures :parameters

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:type => 'admin',
      :id => parameters(:parameter_admin_aproach_types).to_param}
    public_actions = []
    private_actions = [
      [:get, :index, {:type => 'admin'}],
      [:get, :show, id_param],
      [:get, :edit, id_param],
      [:patch, :update, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list parameters' do
    perform_auth
    get :index, :type => 'admin'
    assert_response :success
    assert_not_nil assigns(:parameters)
    assert_select '#error_body', false
    assert_template 'parameters/index'
  end

  test 'show parameter' do
    perform_auth
    get :show, :type => 'admin',
      :id => parameters(:parameter_admin_aproach_types).id
    assert_response :success
    assert_not_nil assigns(:parameter)
    assert_select '#error_body', false
    assert_template 'parameters/show'
  end

  test 'edit parameter' do
    perform_auth
    get :edit, :type => 'admin',
      :id => parameters(:parameter_admin_aproach_types).id
    assert_response :success
    assert_not_nil assigns(:parameter)
    assert_select '#error_body', false
    assert_template 'parameters/edit'
  end

  test 'update parameter' do
    perform_auth
    patch :update, {
      :type => 'admin',
      :id => parameters(:parameter_security_password_count).id,
      :parameter => {
        :value => 'New value',
        :description => 'New description'
      }
    }
      
    assert_redirected_to parameters_url(:type => 'admin')
    assert_not_nil assigns(:parameter)
    assert_equal 'New value', assigns(:parameter).value
    assert_equal 'New description', assigns(:parameter).description
  end

  test 'update parameter with array value' do
    perform_auth
    patch :update, {
      :type => 'admin',
      :id => parameters(:parameter_admin_control_objective_qualifications).id,
      :parameter => {
        :key_1 => 'New key 1',
        :value_1 => '1',
        :key_2 => 'New key 2',
        :value_2 => '2',
        :key_3 => 'New key 3',
        :value_3 => '3',
        :key_4 => 'New key 4',
        :value_4 => '4',
        :description => 'New description'
      }
    }
      
    assert_redirected_to parameters_url(:type => 'admin')
    assert_not_nil assigns(:parameter)
    assert_equal 'New description', assigns(:parameter).description
    assert_equal [['New key 1', '1'], ['New key 2', '2'], ['New key 3', '3'],
      ['New key 4', '4']], assigns(:parameter).value
  end

  test 'versioning' do
    perform_auth

    assert_no_difference 'Parameter.count' do
      patch :update, {
        :type => 'admin',
        :id => parameters(:parameter_security_password_count).id,
        :parameter => {
          :value => 'New value',
          :description => 'New description'
        }
      }

      assert_redirected_to parameters_url(:type => 'admin')
      assert_not_nil assigns(:parameter)
      assert_equal 'New value', assigns(:parameter).value
      assert_equal 'New description', assigns(:parameter).description
    end
  end
end
