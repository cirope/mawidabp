class SessionsController < ApplicationController
  before_action :auth, only: [:destroy]
  before_action :set_admin_mode, :set_organization, only: [:create]
  before_action :set_title, except: [:destroy]

  def new
    auth_user = User.find(session[:user_id]) if session[:user_id]

    if auth_user && auth_user.is_enable? && auth_user.logged_in?
      redirect_to welcome_url
    elsif redirect_to_saml?
      redirect_to new_saml_session_url
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
    logout_params = { saml_logout: true } if current_organization.saml_provider.present?

    if session[:record_id] && LoginRecord.exists?(session[:record_id])
      LoginRecord.find(session[:record_id]).end!
    end

    @auth_user.logout! if @auth_user

    restart_session
    redirect_to_login t('message.session_closed_correctly'), :notice, logout_params
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
      session[:last_access] = Time.zone.now
      session[:user_id]     = user.id

      user.logged_in! session[:last_access]
    end

    def redirect_to_saml?
      current_organization&.saml_provider.present? &&
        params[:saml_error].blank? &&
        params[:saml_logout].blank?
    end
end
