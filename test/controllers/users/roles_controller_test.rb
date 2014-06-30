require 'test_helper'

class Users::RolesControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'should get index' do
    xhr :get, :index, id: organizations(:cirope).id, format: 'json'
    assert_response :success
    roles = ActiveSupport::JSON.decode @response.body
    assert roles.present?
    assert roles.any? { |r| r.first == roles(:admin_role).name }
  end
end
