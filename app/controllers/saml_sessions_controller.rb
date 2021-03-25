require 'idp_settings_adapter'

class SamlSessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  before_action :set_saml_config

  def new
    if @saml_config
      saml_request = OneLogin::RubySaml::Authrequest.new
      action = saml_request.create @saml_config

      redirect_to action
    else
      redirect_to new_session_url
    end
  end

  def metadata
    meta = OneLogin::RubySaml::Metadata.new

    render xml: meta.generate(@saml_config)
  end

  def create
    auth = Authentication.new params, request, session, current_organization, false

    if auth.authenticated?
      flash.notice = auth.message

      set_session_values auth.user
    else
      flash.alert = auth.message
    end

    redirect_to auth.redirect_url
  end

  private

    def set_saml_config
      if current_organization&.saml_provider.present?
        @saml_config = IdpSettingsAdapter.saml_settings current_organization.saml_provider
      end
    end

    def set_session_values user
      session[:last_access] = Time.zone.now
      session[:user_id]     = user.id

      user.logged_in! session[:last_access]
    end
end
