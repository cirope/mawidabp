class MfaSessionsController < ApplicationController

  layout 'public'

  before_action :auth, :set_title

  def new
  end

  def create
    if @auth_user.google_authentic?(params[:mfa_code])
      UserMfaSession.create(@auth_user)

      redirect_to @session[:go_to] || welcome_url
    else
      flash.now.alert = t 'message.invalid_code'

      render 'new', status: :unprocessable_entity
    end
  end
end
