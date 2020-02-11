require 'test_helper'

class NewsControllerTest < ActionController::TestCase
  setup do
    @news = news :announcement

    login
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:news)
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should create news' do
    assert_difference 'News.count' do
      post :create, params: {
        news: {
          title: @news.title,
          description: @news.description,
          body: @news.body,
          published_at: I18n.l(Time.zone.today)
        }
      }
    end

    assert_redirected_to news_url(assigns(:news))
  end

  test 'should show news' do
    get :show, params: { id: @news }
    assert_response :success
  end

  test 'should get edit' do
    get :edit, params: { id: @news }
    assert_response :success
  end

  test 'should update news' do
    patch :update, params: {
      id: @news,
      news: { title: 'New title' }
    }
    assert_redirected_to news_url(assigns(:news))
  end

  test 'should destroy news' do
    assert_difference 'News.count', -1 do
      delete :destroy, params: { id: @news }
    end

    assert_redirected_to news_index_url
  end

  test 'auto complete for tagging' do
    get :auto_complete_for_tagging, params: {
      q: 'brea',
      kind: 'news'
    }, as: :json
    assert_response :success

    response_tags = ActiveSupport::JSON.decode @response.body

    assert_equal 1, response_tags.size
    assert response_tags.all? { |t| t['label'].match /brea/i }

    get :auto_complete_for_tagging, params: {
      q: 'x_none',
      kind: 'news'
    }, as: :json
    assert_response :success

    response_tags = ActiveSupport::JSON.decode @response.body

    assert_equal 0, response_tags.size

    tag = tags :important

    tag.update! obsolete: true

    get :auto_complete_for_tagging, params: {
      q: 'impor',
      completion_state: 'incomplete',
      kind: 'finding'
    }, as: :json

    assert_response :success

    response_tags = ActiveSupport::JSON.decode @response.body

    assert_equal 0, response_tags.size
  end
end
