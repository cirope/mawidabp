class WelcomeController < ApplicationController
  before_action :auth

  def index
    @title   = t 'welcome.index_title'

    unless @auth_user.audited?
      @news = News.list.published.order(published_at: :desc).limit(6)
    end
  end
end
