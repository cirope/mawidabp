class SessionsController < ApplicationController
  include Sessions

  before_action :auth, only: [:destroy]
  before_action :set_title, except: [:destroy]

  def new
  end

  def create
    if params[:user].present?
      if redirect_to_saml? && !@current_user&.recovery?
        redirect_to new_saml_session_url
      else
        store_user params[:user]

        redirect_to signin_url
      end
    else
      flash.now.alert = t 'message.invalid_user_or_email'

      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    logout_params = { saml_logout: true } if current_organization&.saml_provider.present?

    if session[:record_id] && LoginRecord.exists?(session[:record_id])
      LoginRecord.find(session[:record_id]).end!
    end

    @auth_user.logout! if @auth_user

    restart_session
    redirect_to_login t('message.session_closed_correctly'), :notice, logout_params
  end

  private

    def redirect_to_saml?
      current_organization&.saml_provider.present? &&
        params[:saml_error].blank? &&
        params[:saml_logout].blank?
    end
end
