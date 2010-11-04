require 'test_helper'

# Pruebas para el controlador de contenidos de ayuda
class HelpContentsControllerTest < ActionController::TestCase
  fixtures :help_contents

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => help_contents(:help_es).to_param}
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

  test 'list help_contents' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:help_contents)
    assert_select '#error_body', false
    assert_template 'help_contents/index'
  end

  test 'show help_content' do
    perform_auth
    get :show, :id => help_contents(:help_es).id
    assert_response :success
    assert_not_nil assigns(:help_content)
    assert_select '#error_body', false
    assert_template 'help_contents/show'
  end

  test 'show content help' do
    perform_auth
    get :show_content, :id => help_items(:help_item_1_es).id
    assert_response :success
    assert_not_nil assigns(:help_item)
    assert_select '#error_body', false
    assert_template 'help_contents/show_content'
  end

  test 'show content help whitout id' do
    perform_auth
    get :show_content
    assert_response :success
    assert_not_nil assigns(:help_item)
    assert_select '#error_body', false
    assert_template 'help_contents/show_content'
  end

  test 'new help_content' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:help_content)
    assert_select '#error_body', false
    assert_template 'help_contents/new'
  end

  test 'create help_content' do
    perform_auth
    assert_difference ['HelpContent.count', 'HelpItem.count'] do
      post :create, {
        :help_content => {
          :language => 'it',
          :help_items_attributes => {
            :new => {
              :name => 'New name',
              :description => 'New description',
              :order_number => 1
            }
          }
        }
      }
    end

    help_content = HelpContent.find_by_language 'it'
    assert_redirected_to show_content_help_content_path(
      help_content.help_items.first)
  end

  test 'edit help_content' do
    perform_auth
    get :edit, :id => help_contents(:help_es).id
    assert_response :success
    assert_not_nil assigns(:help_content)
    assert_select '#error_body', false
    assert_template 'help_contents/edit'
  end

  test 'update help_content' do
    assert_no_difference ['HelpContent.count', 'HelpItem.count'] do
      perform_auth
      put :update, {
        :id => help_contents(:help_es).id,
        :help_content => {
          :language => 'it',
          :help_items_attributes => {
            help_items(:help_item_1_es).id => {
              :id => help_items(:help_item_1_es).id,
              :name => 'Updated name',
              :description => 'Updated description',
              :order_number => 1
            }
          }
        }
      }
    end

    assert_redirected_to show_content_help_content_path(
      help_items(:help_item_1_es))
    assert_not_nil assigns(:help_content)
    assert_equal 'it', assigns(:help_content).language
    assert_equal 'Updated name', HelpItem.find(
      help_items(:help_item_1_es).id).name
  end

  test 'destroy help_content' do
    perform_auth
    assert_difference 'HelpContent.count', -1 do
      delete :destroy, :id => help_contents(:help_es).id
    end

    assert_redirected_to help_contents_path
  end
end