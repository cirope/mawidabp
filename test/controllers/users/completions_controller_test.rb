require 'test_helper'

class Users::CompletionsControllerTest < ActionController::TestCase
  setup do
    login
  end

  test 'auto complete for user' do
    get :index, xhr: true, params: {
      search: {
        query: 'bar',
        columns: User::COLUMNS_FOR_SEARCH.keys
      }
    }, as: :json

    assert_response :success
    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /bar/i }
  end

  test 'auto complete for corporate user' do
    get :index, xhr: true, params: {
      search: {
        query: 'corporate',
        columns: User::COLUMNS_FOR_SEARCH.keys
      }
    }, as: :json

    assert_response :success
    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /corporate/i }
  end

  test 'list blank users' do
    get :index, xhr: true, params: {
      search: {
        query: 'blank',
        columns: User::COLUMNS_FOR_SEARCH.keys
      }
    }, as: :json

    assert_response :success
    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /blank/i }
  end

  test 'list none users' do
    get :index, xhr: true, params: {
      search: {
        query: 'xyz',
        columns: User::COLUMNS_FOR_SEARCH.keys
      }
    }, as: :json
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size
  end
end
