require 'test_helper'

class Polls::UsersControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'list admin users' do
    get :index, xhr: true, params: { q: 'poll' }, as: :json

    assert_response :success
    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /poll/i }
  end

  test 'list blank users' do
    get :index, xhr: true, params: { q: 'blank' }, as: :json

    assert_response :success
    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /blank/i }
  end

  test 'list none users' do
    get :index, xhr: true, params: { q: 'xyz' }, as: :json

    assert_response :success
    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size
  end
end
