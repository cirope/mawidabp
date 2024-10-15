class MfaSessionsController < ApplicationController

  layout 'public'

  before_action :auth, :set_title

  # GET mfa_sessions/new
  def new
  end

  # POST mfa_sessions
  def create
    if @auth_user.google_authentic?(params[:mfa_code])
      @auth_user.mfa_config_done! unless @auth_user.mfa_done

      UserMfaSession.create(@auth_user)

      redirect_to welcome_url
    else
      flash.now.alert = t 'message.invalid_code'

      render 'new', status: :unprocessable_entity
    end
  end
end
