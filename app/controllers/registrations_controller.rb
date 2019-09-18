class RegistrationsController < ApplicationController
  before_action :check_public_registration_enabled?, :set_title

  respond_to :html

  def show
  end

  def new
    @registration = Registration.new
  end

  def create
    @registration = Registration.new registration_params

    @registration.save

    respond_with @registration, location: registration_path(1)
  end

  private

    def registration_params
      params.require(:registration).permit(
        :organization, :user, :name, :last_name, :email
      )
    end

    def check_public_registration_enabled?
      unless ENABLE_PUBLIC_REGISTRATION
        redirect_to root_path, alert: t('message.insufficient_privileges')
      end
    end
end
