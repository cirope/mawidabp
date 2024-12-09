class SessionsController < ApplicationController
  include Sessions

  layout 'public'

  before_action :auth, only: [:destroy]
  before_action :set_title, except: [:destroy]

  def new
    available_locales = I18n.available_locales.map(&:to_s)
    locale            = params[:locale]

    if available_locales.include?(locale)
      session[:locale] = locale
      I18n.locale      = locale
    end
  end

  def create
    if params[:user].present?
      if redirect_to_saml? && !@current_user&.recovery?
        saml_request = OneLogin::RubySaml::Authrequest.new
        action       = saml_request.create saml_config

        @current_user&.update_saml_request_id saml_request.request_id

        redirect_to action
      else
        store_user params[:user]

        redirect_to signin_url
      end
    else
      redirect_to_login t('message.invalid_user_or_email'), :alert
    end
  end

  def destroy
    logout_params = { saml_logout: true } if current_organization&.saml_provider.present?

    if session[:record_id] && LoginRecord.exists?(session[:record_id])
      LoginRecord.find(session[:record_id]).end!
    end

    @auth_user.logout! if @auth_user

    UserMfaSession.destroy if @auth_user&.require_mfa?

    restart_session
    redirect_to_login t('message.session_closed_correctly'), :notice, logout_params
  end

  private
    def redirect_to_saml?
      current_organization&.saml_provider.present? &&
        params[:saml_error].blank? &&
        params[:saml_logout].blank?
    end

    def saml_config
      IdpSettingsAdapter.saml_settings current_organization.saml_provider
    end
end
