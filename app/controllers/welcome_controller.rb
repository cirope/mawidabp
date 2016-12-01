class WelcomeController < ApplicationController
  before_action :auth

  def index
    @title   = t 'welcome.index_title'
    template = @auth_user.audited? ? 'audited' : 'auditor'

    render template: "welcome/#{template}_index"
  end
end
