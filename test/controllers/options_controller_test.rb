require "test_helper"

class OptionsControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get options_edit_url
    assert_response :success
  end

  test "should get update" do
    get options_update_url
    assert_response :success
  end
end
