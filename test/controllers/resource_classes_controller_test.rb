require 'test_helper'

# Pruebas para el controlador de recursos
class ResourceClassesControllerTest < ActionController::TestCase
  fixtures :resource_classes

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {id: resource_classes(:human_resources).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:patch, :update, id_param],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list resource classes' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:resource_classes)
    assert_select '#error_body', false
    assert_template 'resource_classes/index'
  end

  test 'show resource class' do
    perform_auth
    get :show, id: resource_classes(:human_resources).id
    assert_response :success
    assert_not_nil assigns(:resource_class)
    assert_select '#error_body', false
    assert_template 'resource_classes/show'
  end

  test 'new resource class' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:resource_class)
    assert_select '#error_body', false
    assert_template 'resource_classes/new'
  end

  test 'create resource class' do
    assert_difference ['ResourceClass.count', 'Resource.count'] do
      perform_auth
      post :create, {
        resource_class: {
          name: 'New resource class',
          resource_class_type: ResourceClass::TYPES[:human],
          resources_attributes: [
            {
              name: 'New name',
              description: 'New description',
              cost_per_unit: '15.33'
            }
          ]
        }
      }
    end
  end

  test 'edit resource class' do
    perform_auth
    get :edit, id: resource_classes(:human_resources).id
    assert_response :success
    assert_not_nil assigns(:resource_class)
    assert_select '#error_body', false
    assert_template 'resource_classes/edit'
  end

  test 'update resource class' do
    assert_no_difference 'ResourceClass.count' do
      assert_difference 'Resource.count' do
        perform_auth
        patch :update, {
          id: resource_classes(:human_resources).id,
          resource_class: {
            name: 'Updated resource class',
            resource_class_type: ResourceClass::TYPES[:human],
            resources_attributes: [
              {
                id: resources(:auditor_resource).id,
                name: 'Updated name',
                description: 'Updated description',
                cost_per_unit: '14.33'
              }, {
                name: 'New name from update',
                description: 'New description from update',
                cost_per_unit: '15.53'
              }
            ]
          }
        }
      end
    end

    assert_redirected_to resource_classes_url
    assert_not_nil assigns(:resource_class)
    assert_equal 'Updated resource class', assigns(:resource_class).name
  end

  test 'destroy resource class' do
    perform_auth
    assert_difference 'ResourceClass.count', -1 do
      delete :destroy, id: resource_classes(:human_resources).id
    end

    assert_redirected_to resource_classes_url
  end
end
