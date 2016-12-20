class WelcomeController < ApplicationController
  before_action :auth

  def index
    @title   = t 'welcome.index_title'
    template = @auth_user.audited? ? 'audited' : 'auditor'

    unless @auth_user.audited?
      @news = News.list.published.order(published_at: :desc).limit(6)
    end

    render template: "welcome/#{template}_index"
  end
end
