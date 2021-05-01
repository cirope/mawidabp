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

  test 'should create activity group' do
    assert_difference %w(ActivityGroup.count Activity.count) do
      post :create, params: {
        activity_group: {
          name: 'New activity group',
          activities_attributes: {
            '0' => {
              name: 'New activity'
            }
          }
        }
      }
    end

    assert_redirected_to activity_group_url(assigns(:activity_group))
  end

  test 'should show activity group' do
    get :show, params: { id: @activity_group }

    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @activity_group }

    assert_response :success
  end

  test 'should update activity group' do
    assert_no_difference 'Activity.count' do
      activity = activities :special_activity

      patch :update, params: {
        id: @activity_group, activity_group: {
          name: 'Updated name',
          activities_attributes: {
            activity.id => {
              id:   activity.id,
              name: activity.name
            }
          }
        }
      }
    end

    assert_redirected_to activity_group_url(@activity_group)
  end

  test 'should destroy activity group' do
    assert_difference 'ActivityGroup.count', -1 do
      delete :destroy, params: { id: @activity_group }
    end

    assert_redirected_to activity_groups_url
  end
end
