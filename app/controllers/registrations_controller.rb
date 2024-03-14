class RegistrationsController < ApplicationController
  before_action :check_public_registration_enabled?, :set_title

  layout 'public'

  def show
  end

  def new
    @registration = Registration.new
  end

  def create
    @registration = Registration.new registration_params

    if @registration.save
      redirect_with_notice @registration, url: registration_path
    else
      render 'new', status: :unprocessable_entity
    end
  end

  private

    def registration_params
      params.require(:registration).permit(
        :organization_name, :user, :name, :last_name, :email
      )
    end

    def check_public_registration_enabled?
      unless ENABLE_PUBLIC_REGISTRATION
        redirect_to root_path, alert: t('message.insufficient_privileges')
      end
    end
end
