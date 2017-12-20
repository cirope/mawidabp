require 'test_helper'

class Users::RegistrationRolesControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index, xhr: true, params: {
      id: organizations(:cirope).id,
      hash: groups(:main_group).admin_hash
    }, as: :json

    assert_response :success
    roles = ActiveSupport::JSON.decode @response.body
    assert roles.present?
    assert roles.any? { |r| r.first == roles(:admin_role).name }
  end

  test 'get initial roles with invalid hash' do
    assert_raise ActiveRecord::RecordNotFound do
      get :index, xhr: true, params: {
        id: organizations(:cirope).id,
        hash: 'xxx'
      }, as: :json
    end
  end
end
