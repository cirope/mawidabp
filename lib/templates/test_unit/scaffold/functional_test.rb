require 'test_helper'

<% module_namespacing do -%>
class <%= controller_class_name %>ControllerTest < ActionController::TestCase

  setup do
    @<%= singular_table_name %> = <%= table_name %>(:one)

    login
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:<%= table_name %>)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create <%= singular_table_name %>' do
    assert_difference '<%= class_name %>.count' do
      post :create, params: {
        <%= singular_table_name %>: {
          <%= attributes.map { |attribute| "#{attribute.name}: nil" }.join(', ') %>
        }
      }
    end

    assert_redirected_to <%= singular_table_name %>_url(assigns(:<%= singular_table_name %>))
  end

  test 'should show <%= singular_table_name %>' do
    get :show, params: { id: <%= "@#{singular_table_name}" %> }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: <%= "@#{singular_table_name}" %> }
    assert_response :success
  end

  test 'should update <%= singular_table_name %>' do
    patch :update, params: {
      id: @<%= singular_table_name %>, <%= "#{singular_table_name}: { attr: 'value' }" %>
    }
    assert_redirected_to <%= singular_table_name %>_url(assigns(:<%= singular_table_name %>))
  end

  test 'should destroy <%= singular_table_name %>' do
    assert_difference '<%= class_name %>.count', -1 do
      delete :destroy, params: { id: <%= "@#{singular_table_name}" %> }
    end

    assert_redirected_to <%= index_helper %>_url
  end
end
<% end -%>
