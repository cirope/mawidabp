class SettingsController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_setting, only: [:show, :edit, :update]
  before_action :set_title, except: :destroy

  # GET /settings
  def index
    @settings = current_organization.settings.page params[:page]
  end

  # GET /settings/1
  def show
  end

  # GET /settings/1/edit
  def edit
  end

  # PATCH/PUT /settings/1
  def update
    update_resource @setting, setting_params
    respond_with @setting unless response_body
  end

  private

    def set_setting
      @setting = current_organization.settings.find params[:id]
    end

    def setting_params
      params.require(:setting).permit :value, :description
    end
end
