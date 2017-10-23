class UsersController < ApplicationController
  include Users::Finders
  include Users::Params

  respond_to :html

  before_action :auth, :check_privileges
  before_action :check_ldap, only: [:new, :create]
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # * GET /users
  def index
    @users = users

    respond_to do |format|
      format.html
      format.pdf  { redirect_to pdf.relative_path }
    end
  end

  # * GET /users/1
  def show
  end

  # * GET /users/new
  def new
    @user = User.new
  end

  # * GET /users/1/edit
  def edit
  end

  # * POST /users
  def create
    @user = User.new user_params

    @user.roles.each { |r| r.inject_auth_privileges @auth_privileges }
    @user.send_welcome_email if @user.save
    @user.password = @user.password_confirmation = nil

    respond_with @user, location: users_url
  end

  # * PATCH /users/1
  def update
    params[:user][:child_ids] ||= []
    params[:user].delete :lock_version if @user == @auth_user

    update_resource @user, user_params

    @user.send_notification_if_necesary if @user.errors.empty?

    respond_with @user, location: users_url
  end

  # * DELETE /users/1
  def destroy
    @user.disable

    respond_with @user, location: users_url
  end

  private

    def users
      User.includes(:organizations).where(conditions).not_hidden.order(
        "#{User.quoted_table_name}.#{User.qcn('user')} ASC"
      ).references(:organizations).page(params[:page])
    end

    def pdf
      UserPdf.create(
        columns: @columns,
        query: @query,
        users: @users.except(:limit),
        current_organization: current_organization
      )
    end

    def conditions
      default_conditions = {
        organization_roles: { organization_id: current_organization.id }
      }

      build_search_conditions User, default_conditions
    end

    def check_ldap
      if current_organization.ldap_config
        redirect_to_login t('message.insufficient_privileges'), :alert
      end
    end
end
