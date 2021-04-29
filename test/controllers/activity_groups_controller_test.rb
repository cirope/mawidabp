require 'test_helper'

class ActivityGroupsControllerTest < ActionController::TestCase

  setup do
    @activity_group = activity_groups :special_activities

    login
  end

  test 'should get index' do
    get :index

    assert_response :success
    assert_not_nil assigns(:activity_groups)
  end

  test 'should get new' do
    get :new

    assert_response :success
  end

  test 'should create activity_group' do
    assert_difference 'ActivityGroup.count' do
      post :create, params: {
        activity_group: {
          name: 'New activity group'
        }
      }
    end

    assert_redirected_to activity_group_url(assigns(:activity_group))
  end

  test 'should show activity_group' do
    get :show, params: { id: @activity_group }

    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @activity_group }

    assert_response :success
  end

  test 'should update activity_group' do
    patch :update, params: {
      id: @activity_group, activity_group: { name: 'Updated name' }
    }

    assert_redirected_to activity_group_url(assigns(:activity_group))
  end

  test 'should destroy activity_group' do
    assert_difference 'ActivityGroup.count', -1 do
      delete :destroy, params: { id: @activity_group }
    end

    assert_redirected_to activity_groups_url
  end
end
