require 'test_helper'

# Pruebas para el controlador de grupos
class GroupsControllerTest < ActionController::TestCase
  fixtures :groups

  setup do
    login prefix: APP_ADMIN_PREFIXES.first
  end

  test 'list groups' do
    get :index
    assert_response :success
    assert_not_nil assigns(:groups)
    assert_template 'groups/index'
  end

  test 'show group' do
    get :show, :id => groups(:main_group).id
    assert_response :success
    assert_not_nil assigns(:group)
    assert_template 'groups/show'
  end

  test 'new group' do
    get :new
    assert_response :success
    assert_not_nil assigns(:group)
    assert_template 'groups/new'
  end

  test 'create group' do
    counts_array = ['Group.count', 'Organization.count',
      'ActionMailer::Base.deliveries.size']

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference counts_array do
      post :create, {
        :group => {
          :name => 'New group',
          :description => 'New group description',
          :admin_email => 'new_group@test.com',
          :send_notification_email => '1',
          :organizations_attributes => [
            {
              :name => 'New organization',
              :prefix => 'new-organization',
              :description => 'New organization description'
            }
          ]
        }
      }
    end

    assert_equal Group.find_by_name('New group').id,
      Organization.find_by_prefix('new-organization').group_id
  end

  test 'create group without notification' do

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference ['Group.count', 'Organization.count'] do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        post :create, {
          :group => {
            :name => 'New group',
            :description => 'New group description',
            :admin_email => 'new_group@test.com',
            :send_notification_email => '',
            :organizations_attributes => [
              {
                :name => 'New organization',
                :prefix => 'new-organization',
                :description => 'New organization description'
              }
            ]
          }
        }
      end
    end

    assert_equal Group.find_by_name('New group').id,
      Organization.find_by_prefix('new-organization').group_id
  end

  test 'edit group' do
    get :edit, :id => groups(:main_group).id
    assert_response :success
    assert_not_nil assigns(:group)
    assert_template 'groups/edit'
  end

  test 'update group' do
    assert_no_difference ['Group.count', 'Organization.count'] do
      patch :update, {
        :id => groups(:main_group).id,
        :group => {
          :name => 'Updated group',
          :description => 'Updated group description',
          :admin_email => 'updated_group@test.com',
          :send_notification_email => '',
          :organizations_attributes => [
            {
              :id => organizations(:default_organization).id,
              :name => 'Updated default organization',
              :prefix => 'default-testing-organization',
              :description => 'Updated default organization description'
            }
          ]
        }
      }
    end

    assert_redirected_to groups_url
    assert_not_nil assigns(:group)
    assert_equal 'Updated group', assigns(:group).name
    assert_equal 'Updated default organization',
      Organization.find(organizations(:default_organization).id).name
  end

  test 'destroy group' do
    assert_difference 'Group.count', -1 do
      delete :destroy, :id => groups(:second_group).id
    end

    assert_redirected_to groups_url
  end
end
