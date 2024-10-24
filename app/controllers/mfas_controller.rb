class MfasController < ApplicationController

  layout 'public'

  before_action :auth, :set_title

  # GET mfas/new
  def new
  end

  # POST mfas
  def create
    if @auth_user.google_authentic?(params[:code])
      @auth_user.mfa_config_done! unless @auth_user.mfa_configured_at

      UserMfaSession.create @auth_user

      redirect_to welcome_url
    else
      flash.now.alert = t 'message.invalid_code'

      render 'new', status: :unprocessable_entity
    end
  end
end
