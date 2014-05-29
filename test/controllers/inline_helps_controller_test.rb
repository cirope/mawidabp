require 'test_helper'

# Pruebas para el controlador de contenidos de ayuda en línea
class InlineHelpsControllerTest < ActionController::TestCase
  fixtures :inline_helps

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => inline_helps(:es_review_identification).to_param}
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

  test 'list inline_helps' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:inline_helps)
    assert_template 'inline_helps/index'
  end

  test 'show inline_help' do
    login
    get :show, :id => inline_helps(:es_review_identification).id
    assert_response :success
    assert_not_nil assigns(:inline_help)
    assert_template 'inline_helps/show'
  end

  test 'new inline_help' do
    login
    get :new
    assert_response :success
    assert_not_nil assigns(:inline_help)
    assert_template 'inline_helps/new'
  end

  test 'create inline_help' do
    login
    assert_difference 'InlineHelp.count' do
      post :create, {
        :inline_help => {
          :language => 'it',
          :name => 'review_score',
          :content => 'Review score explanation'
        }
      }
    end

    assert_redirected_to inline_helps_url
  end

  test 'edit inline_help' do
    login
    get :edit, :id => inline_helps(:es_review_identification).id
    assert_response :success
    assert_not_nil assigns(:inline_help)
    assert_template 'inline_helps/edit'
  end

  test 'update inline_help' do
    assert_no_difference 'InlineHelp.count' do
      login
      patch :update, {
        :id => inline_helps(:es_review_identification).id,
        :inline_help => {
          :language => 'es',
          :name => 'review_identification',
          :content => 'Updated content'
        }
      }
    end

    assert_redirected_to inline_helps_url
    assert_not_nil assigns(:inline_help)
    assert_equal 'es', assigns(:inline_help).language
    assert_equal 'Updated content', InlineHelp.find(
      inline_helps(:es_review_identification).id).content
  end

  test 'destroy inline_help' do
    login
    assert_difference 'InlineHelp.count', -1 do
      delete :destroy, :id => inline_helps(:es_review_identification).id
    end

    assert_redirected_to inline_helps_url
  end
end
