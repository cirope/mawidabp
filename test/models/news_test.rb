require 'test_helper'

class NewsTest < ActiveSupport::TestCase
  def setup
    @news = news :announcement
  end

  test 'blank attributes' do
    @news.title = ''
    @news.body = ''
    @news.organization = nil
    @news.group = nil

    assert @news.invalid?
    assert_error @news, :title, :blank
    assert_error @news, :body, :blank
    assert_error @news, :organization, :blank
    assert_error @news, :group, :blank
  end

  test 'validates attributes length' do
    @news.title = 'abcde' * 52

    assert @news.invalid?
    assert_error @news, :title, :too_long, count: 255
  end
end
