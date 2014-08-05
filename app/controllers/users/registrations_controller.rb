class Users::RegistrationsController < ApplicationController
  include Users::Params

  respond_to :html

  before_action :set_group, :check_stale_group

  layout 'clean'

  # * GET /users/registrations/new?hash=xxxx
  def new
    @user = User.new
  end

  # * POST /users/registrations
  def create
    @user = User.new user_params

    if @user.save
      @group.update! admin_hash: nil
      @user.send_welcome_email

      redirect_to login_url, notice: t('flash.actions.create.notice', resource_name: User.model_name.human)
    else
      render 'new'
    end
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
