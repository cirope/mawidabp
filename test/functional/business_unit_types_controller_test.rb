require 'test_helper'

# Pruebas para el controlador de tipos de unidades de negocio
class BusinessUnitTypesControllerTest < ActionController::TestCase
  fixtures :business_unit_types

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => business_unit_types(:cycle).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:put, :update, id_param],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list business_unit_types' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:business_unit_types)
    assert_select '#error_body', false
    assert_template 'business_unit_types/index'
  end

  test 'show business_unit_type' do
    perform_auth
    get :show, :id => business_unit_types(:cycle).id
    assert_response :success
    assert_not_nil assigns(:business_unit_type)
    assert_select '#error_body', false
    assert_template 'business_unit_types/show'
  end

  test 'new business_unit_type' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:business_unit_type)
    assert_select '#error_body', false
    assert_template 'business_unit_types/new'
  end

  test 'create business_unit_type' do
    assert_difference ['BusinessUnitType.count', 'BusinessUnit.count'] do
      perform_auth
      post :create, {
        :business_unit_type => {
          :name => 'New business unit type',
          :business_unit_label => 'New business unit label',
          :project_label => 'New project label',
          :external => '0',
          :business_units_attributes => {
            :new_1 => {
              :name => 'New business unit'
            }
          }
        }
      }
    end

    assert_equal 'New business unit type', assigns(:business_unit_type).name
    assert_equal false, assigns(:business_unit_type).external
    assert_not_nil BusinessUnit.find_by_name('New business unit')
  end

  test 'edit business_unit_type' do
    perform_auth
    get :edit, :id => business_unit_types(:cycle).id
    assert_response :success
    assert_not_nil assigns(:business_unit_type)
    assert_select '#error_body', false
    assert_template 'business_unit_types/edit'
  end

  test 'update business_unit_type' do
    assert_no_difference ['BusinessUnitType.count', 'BusinessUnit.count'] do
      perform_auth
      put :update, {
        :id => business_unit_types(:cycle).id,
        :business_unit_type => {
          :name => 'Updated business unit type',
          :business_unit_label => 'Updated business unit label',
          :project_label => 'Updated project label',
          :external => '0',
          :business_units_attributes => {
            business_units(:business_unit_one).id => {
              :id => business_units(:business_unit_one).id,
              :name => 'Updated business unit one'
            },
            business_units(:business_unit_two).id => {
              :id => business_units(:business_unit_two).id,
              :name => 'Updated business unit two'
            }
          }
        }
      }
    end

    assert_redirected_to business_unit_types_url
    assert_not_nil assigns(:business_unit_type)
    assert_equal 'Updated business unit type', assigns(:business_unit_type).name
    assert_equal 'Updated business unit one',
      BusinessUnit.find(business_units(:business_unit_one).id).name
  end

  test 'destroy business_unit_type' do
    perform_auth
    assert_difference 'BusinessUnitType.count', -1 do
      delete :destroy, :id => business_unit_types(:bcra).id
    end

    assert_redirected_to business_unit_types_url
  end
end