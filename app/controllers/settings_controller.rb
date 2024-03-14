class SettingsController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_setting, only: [:show, :edit, :update]
  before_action :set_title

  # GET /settings
  def index
    @settings = current_organization.settings.order(:id).page params[:page]
  end

  # GET /settings/1
  def show
  end

  # GET /settings/1/edit
  def edit
  end

  # PATCH/PUT /settings/1
  def update
    if @setting.update setting_params
      redirect_with_notice @setting
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  private

    def set_setting
      @setting = current_organization.settings.find params[:id]
    end

    def setting_params
      params.require(:setting).permit :value, :description
    end
end
