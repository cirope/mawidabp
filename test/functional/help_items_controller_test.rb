require 'test_helper'

# Pruebas para el controlador de registros de ayuda
class HelpItemsControllerTest < ActionController::TestCase
  fixtures :help_items

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => help_items(:help_item_1_es).to_param}
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

  test 'list help items' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:help_items)
    assert_select '#error_body', false
    assert_template 'help_items/index'
  end

  test 'show help item' do
    perform_auth
    get :show, :id => help_items(:help_item_1_es).id
    assert_response :success
    assert_not_nil assigns(:help_item)
    assert_select '#error_body', false
    assert_template 'help_items/show'
  end

  test 'new help item' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:help_item)
    assert_select '#error_body', false
    assert_template 'help_items/new'
  end

  test 'create help item' do
    perform_auth
    assert_difference 'HelpItem.count', 2 do
      post :create, {
        :help_item => {
          :help_content => help_contents(:help_es),
          :name => 'New name',
          :description => 'New description',
          :order_number => 10,
          :children_attributes => {
            :new => {
              :name => 'New child name',
              :description => 'New child description',
              :order_number => 1
            }
          }
        }
      }
    end

    help_item = HelpItem.first(
      :conditions => {:name => 'New name'},
      :order => 'created_at DESC'
    )
    assert_redirected_to show_content_help_content_path(help_item)
  end

  test 'edit help item' do
    perform_auth
    get :edit, :id => help_items(:help_item_1_es).id
    assert_response :success
    assert_not_nil assigns(:help_item)
    assert_select '#error_body', false
    assert_template 'help_items/edit'
  end

  test 'update help item' do
    assert_no_difference 'HelpItem.count' do
      perform_auth
      put :update, {
        :id => help_items(:help_item_1_es).id,
        :help_item => {
          :name => 'Updated name',
          :description => 'Updated description',
          :order_number => 1,
          :children_attributes => {
            help_items(:help_item_1_1_es).id => {
              :id => help_items(:help_item_1_1_es).id,
              :name => 'Updated child name',
              :description => 'Updated child description',
              :order_number => 1
            }
          }
        }
      }
    end

    assert_redirected_to show_content_help_content_path(
      help_items(:help_item_1_es))
    assert_not_nil assigns(:help_item)
    assert_equal 'Updated name', assigns(:help_item).name
    assert_equal 'Updated child name', HelpItem.find(
      help_items(:help_item_1_1_es).id).name
  end

  test 'destroy help item' do
    perform_auth
    assert_difference 'HelpItem.count', -2 do
      delete :destroy, :id => help_items(:help_item_1_es).id
    end

    assert_redirected_to help_items_path
  end
end