class SessionsController < ApplicationController
  before_action :auth, only: [:destroy]
  before_action :set_admin_mode, :set_organization, only: [:create]
  before_action :set_title, except: [:destroy]

  def new
    auth_user = User.find(session[:user_id]) if session[:user_id]

    if auth_user && auth_user.is_enable? && auth_user.logged_in?
      redirect_to welcome_url
    end
  end

  def create
    auth = Authentication.new params, request, session, current_organization, @admin_mode

    if auth.authenticated?
      flash.notice = auth.message
      set_session_values auth.user
    else
      flash.alert = auth.message
    end

    redirect_to auth.redirect_url
  end

  def destroy
    if session[:record_id] && LoginRecord.exists?(session[:record_id])
      LoginRecord.find(session[:record_id]).end!
    end

    @auth_user.logout! if @auth_user

    restart_session
    redirect_to_login t('message.session_closed_correctly')
  end

  private

    def set_admin_mode
      @admin_mode = APP_ADMIN_PREFIXES.include?(request.subdomains.first)
    end

    def set_organization
      unless (current_organization || @admin_mode)
        flash.alert = t 'message.no_organization'
        redirect_to login_url
      end
    end

    def set_session_values user
      session[:last_access] = Time.now
      user.logged_in!(session[:last_access])
      session[:user_id] = user.id
    end
end
