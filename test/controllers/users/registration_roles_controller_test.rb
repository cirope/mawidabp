require 'test_helper'

class Users::RegistrationRolesControllerTest < ActionController::TestCase
  test 'should get index' do
    xhr :get, :index,
      id: organizations(:cirope).id, format: 'json',
      hash: groups(:main_group).admin_hash

    assert_response :success
    roles = ActiveSupport::JSON.decode @response.body
    assert roles.present?
    assert roles.any? { |r| r.first == roles(:admin_role).name }
  end

  test 'get initial roles with invalid hash' do
    assert_raise ActiveRecord::RecordNotFound do
      xhr :get, :index, id: organizations(:cirope).id, format: 'json', hash: 'xxx'
    end
  end
end
