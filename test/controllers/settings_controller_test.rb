require 'test_helper'

class SettingsControllerTest < ActionController::TestCase
  setup do
    @setting = settings(:parameter_finding_stale_confirmed_days_default)

    perform_auth
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:settings)
  end

  test "should show setting" do
    get :show, id: @setting
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @setting
    assert_response :success
  end

  test "should update setting" do
    patch :update, {
      id: @setting.id,
      setting: {
        value: 'New value',
        description: 'New description'
      }
    }
    assert_redirected_to setting_path(assigns(:setting))
  end
end
