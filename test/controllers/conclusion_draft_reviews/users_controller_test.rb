require 'test_helper'

class ConclusionDraftReviews::UsersControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'auto complete for user' do
    xhr :get, :index, q: 'bar', format: :json

    assert_response :success
    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /bar/i }
  end

  test 'list blank users' do
    xhr :get, :index, q: 'blank', format: :json

    assert_response :success
    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /blank/i }
  end

  test 'list none users' do
    xhr :get, :index, q: 'xyz', format: :json
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size
  end
end
