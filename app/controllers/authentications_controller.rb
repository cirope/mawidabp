class AuthenticationsController < ApplicationController
  include Sessions

  before_action :set_title, except: [:destroy]

  def new
    @username = username
  end

  def create
    params[:user] = username

    auth = Authentication.new params, request, session,
      current_organization, @admin_mode, @current_user

    if auth.authenticated?
      flash.notice = auth.message

      set_session_values auth.user
    else
      flash.alert = auth.message
    end

    redirect_to auth.redirect_url
  end

  private

    def set_session_values user
      session[:last_access] = Time.zone.now
      session[:user_id]     = user.id

      user.logged_in! session[:last_access]
    end
end
