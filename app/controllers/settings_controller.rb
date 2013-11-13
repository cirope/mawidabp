class SettingsController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_setting, only: [:show, :edit, :update]

  # GET /settings
  def index
    @title = t 'setting.index_title'

    @settings = current_organization.settings.paginate(
      page: params[:page], per_page: APP_LINES_PER_PAGE
    )
  end

  # GET /settings/1
  def show
    @title = t 'setting.show_title'
  end

  # GET /settings/1/edit
  def edit
    @title = t 'setting.edit_title'
  end

  # PATCH/PUT /settings/1
  def update
    if @setting.update(setting_params)
      redirect_to @setting, notice: t('setting.correctly_updated')
    else
      render action: 'edit'
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'setting.stale_object_error'
    redirect_to edit_setting_url(@setting)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting
      @setting = current_organization.settings.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def setting_params
      params.require(:setting).permit(:value, :description)
    end
end
