class Users::PasswordsController < ApplicationController
  include Users::Finders
  include Users::Params

  before_action :set_title
  before_action :set_user, only: [:edit, :update]

  # * GET /users/password/new
  def new
  end

  # * POST /users/passwords
  def create
    @user = find_with_organization user_params[:email], :email

    if @user
      @user.reset_password current_organization
      redirect_to login_url, notice: t('.success')
    else
      redirect_to new_users_password_url, notice: t('.not_found')
    end
  end

  # * GET /users/password/1/edit
  def edit
    @auth_user.password = nil
  end

  # * PATCH /users/password/1
  def update
    @auth_user.password = user_params[:password]
    @auth_user.password_confirmation = user_params[:password_confirmation]

    if @auth_user.valid?
      update_password
    else
      @auth_user.password = @auth_user.password_confirmation = nil
      render action: 'edit'
    end
  rescue ActiveRecord::StaleObjectError
    redirect_to edit_users_password_url(@auth_user), alert: t('user.password_stale_object_error')
  end

  private

    def set_user
      params[:confirmation_hash].blank? ? login_check : load_user_from_hash

      unless @auth_user
        restart_session
        redirect_to login_url, alert: t('users.passwords.update.expired')
      end
    end

    def load_user_from_hash
      Organization.current_id = nil
      @auth_user = User.with_valid_confirmation_hash(params[:confirmation_hash]).take
    end

    def update_password
      PaperTrail.whodunnit ||= @auth_user.id

      save_password
      restart_session
      redirect_to login_url, notice: t('.success')
    end

    def save_password
      @auth_user.encrypt_password
      @auth_user.update!(
        password: @auth_user.password,
        password_confirmation: @auth_user.password,
        password_changed: Date.today,
        change_password_hash: nil,
        enable: true,
        failed_attempts: 0,
        last_access: session[:last_access] || Time.now
      )
    end
end
