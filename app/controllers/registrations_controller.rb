class RegistrationsController < ApplicationController
  before_action :set_title

  def new
    @registration = Registration.new
  end

  def create
    @registration = Registration.new registration_params

    if @registration.save
      render 'created'
    else
      render 'new'
    end
  end

  private

    def registration_params
      params.require(:registration).permit(
        :organization, :user, :name, :last_name, :email, :language
      )
    end
end
