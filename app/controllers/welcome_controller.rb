class WelcomeController < ApplicationController
  before_filter :auth

  def index
    @title = t 'welcome.index_title'

    render :template =>
      "welcome/#{@auth_user.audited? ? 'audited' : 'auditor'}_index"
  end
end