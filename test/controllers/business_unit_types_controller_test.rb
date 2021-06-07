require 'test_helper'

# Pruebas para el controlador de tipos de unidades de negocio
class BusinessUnitTypesControllerTest < ActionController::TestCase
  fixtures :business_unit_types

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = { :params => { :id => business_unit_types(:cycle).to_param } }
    public_actions = []
    private_actions = [
      [:get, :index, {}],
      [:get, :show, id_param],
      [:get, :new, {}],
      [:get, :edit, id_param],
      [:post, :create, {}],
      [:patch, :update, id_param],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      options = action.pop

      send *action, **options
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list business_unit_types' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:business_unit_types)
    assert_template 'business_unit_types/index'
  end

  test 'show business_unit_type' do
    login
    get :show, :params => { :id => business_unit_types(:cycle).id }
    assert_response :success
    assert_not_nil assigns(:business_unit_type)
    assert_template 'business_unit_types/show'
  end

  test 'new business_unit_type' do
    login
    get :new
    assert_response :success
    assert_not_nil assigns(:business_unit_type)
    assert_template 'business_unit_types/new'
  end

  test 'create business_unit_type' do
    assert_difference ['BusinessUnitType.count', 'BusinessUnit.count', 'Tagging.count'] do
      login
      post :create, :params => {
        :business_unit_type => {
          :name => 'New business unit type',
          :business_unit_label => 'New business unit label',
          :project_label => 'New project label',
          :review_prefix => 'NBU',
          :recipients => 'John Doe',
          :sectors => 'Area 51',
          :external => '0',
          :require_tag => '0',
          :require_counts => '0',
          :hide_review_logo => '0',
          :independent_identification => '0',
          :business_units_attributes => [
            {
              :name => 'New business unit',
              :taggings_attributes => [
                :tag_id => tags(:business_unit).id
              ],
              :business_unit_kind_id => business_unit_kinds(:branch).id
            }
          ]
        }
      }
    end

    assert_equal 'New business unit type', assigns(:business_unit_type).name
    assert_equal false, assigns(:business_unit_type).external
    assert_not_nil BusinessUnit.find_by_name('New business unit')
  end

  test 'edit business_unit_type' do
    login
    get :edit, :params => { :id => business_unit_types(:cycle).id }
    assert_response :success
    assert_not_nil assigns(:business_unit_type)
    assert_template 'business_unit_types/edit'
  end

  test 'update business_unit_type' do
    assert_no_difference ['BusinessUnitType.count', 'BusinessUnit.count', 'Tagging.count'] do
      login
      patch :update, :params => {
        :id => business_unit_types(:cycle).id,
        :business_unit_type => {
          :name => 'Updated business unit type',
          :business_unit_label => 'Updated business unit label',
          :project_label => 'Updated project label',
          :review_prefix => 'UBU',
          :recipients => 'John Doe',
          :sectors => 'Area 51',
          :external => '0',
          :require_tag => '0',
          :require_counts => '0',
          :hide_review_logo => '0',
          :independent_identification => '0',
          :business_units_attributes => [
            {
              :id => business_units(:business_unit_one).id,
              :name => 'Updated business unit one',
              :taggings_attributes => [
                id: taggings(:business_unit_business_unit_one).id
              ]
            },
            {
              :id => business_units(:business_unit_two).id,
              :name => 'Updated business unit two',
              :taggings_attributes => [
                id: taggings(:business_unit_business_unit_two).id
              ]
            }
          ]
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
    login
    assert_difference 'BusinessUnitType.count', -1 do
      delete :destroy, :params => { :id => business_unit_types(:bcra).id }
    end

    assert_redirected_to business_unit_types_url
  end

  test 'auto complete for tagging' do
    login

    get :auto_complete_for_tagging, params: {
      q: 'business',
      kind: 'business_unit'
    }, as: :json

    assert_response :success

    response_tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, response_tags.size
    assert response_tags.all? { |t| t['label'].match /business/i }

    get :auto_complete_for_tagging, params: {
      q: 'x_none',
      kind: 'business_unit'
    }, as: :json

    assert_response :success

    response_tags = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, response_tags.size
  end
end
