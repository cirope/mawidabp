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
      post :create, news: {
        title: @news.title,
        description: @news.description,
        body: @news.body,
        published_at: I18n.l(Time.zone.today)
      }
    end

    assert_redirected_to news_url(assigns(:news))
  end

  test 'should show news' do
    get :show, id: @news
    assert_response :success
  end

  test 'should get edit' do
    get :edit, id: @news
    assert_response :success
  end

  test 'should update news' do
    patch :update, id: @news, news: { title: 'New title' }
    assert_redirected_to news_url(assigns(:news))
  end

  test 'should destroy news' do
    assert_difference 'News.count', -1 do
      delete :destroy, id: @news
    end

    assert_redirected_to news_index_url
  end

  test 'auto complete for tagging' do
    get :auto_complete_for_tagging, {
      q: 'brea',
      kind: 'news',
      format: :json
    }
    assert_response :success

    tags = ActiveSupport::JSON.decode @response.body

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /brea/i }

    get :auto_complete_for_tagging, {
      q: 'x_none',
      kind: 'news',
      format: :json
    }
    assert_response :success

    tags = ActiveSupport::JSON.decode @response.body

    assert_equal 0, tags.size
  end
end
