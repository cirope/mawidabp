class Users::RegistrationRolesController < ApplicationController
  respond_to :json

  before_action :set_group, :check_stale_group

  # * GET /users/registration_roles
  def index
    @roles = Role.where organization_id: params[:id]
  end

  private

    def set_group
      @group = Group.find_by! admin_hash: params[:hash]
    end

    def check_stale_group
      if @group.updated_at < BLANK_PASSWORD_STALE_DAYS.days.ago.to_time
        redirect_to login_url, alert: t('message.must_be_authenticated')
      end
    end
end
