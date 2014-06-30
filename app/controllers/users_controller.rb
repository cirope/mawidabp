class UsersController < ApplicationController
  include Users::Finders
  include Users::Params

  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy, :auto_complete_for_user]

  # * GET /users
  def index
    @users = users

    respond_to do |format|
      format.html { redirect_to user_url(@users.first) if one_result?  }
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

    @user.send_notification_if_necesary if @user.update user_params

    respond_with @user, location: users_url
  end

  # * DELETE /users/1
  def destroy
    @user.disable

    respond_with @user, location: users_url
  end

  # * GET /users/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Organization.table_name}.id = :organization_id",
      "#{User.table_name}.hidden = false"
    ]
    conditions << "#{User.table_name}.id <> :self_id" if params[:user_id]
    parameters = {
      organization_id: current_organization.id,
      self_id: params[:user_id]
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.function) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.user) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters[:"user_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @users = User.includes(:organizations).where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order(
      ["#{User.table_name}.last_name ASC", "#{User.table_name}.name ASC"]
    ).references(:organizations).limit(10)

    respond_to do |format|
      format.json { render json: @users }
    end
  end

  private

    def load_privileges #:nodoc:
      if @action_privileges
        @action_privileges.update(
          auto_complete_for_user: :read
        )
      end
    end

    def users
      User.includes(:organizations).where(conditions).not_hidden.order(
        "#{User.table_name}.user ASC"
      ).references(:organizations).page(params[:page])
    end

    def one_result?
      @users.count == 1 && !@query.blank? && !params[:page]
    end

    def pdf
      UserPdf.create(
        columns: @columns,
        query: @query,
        users: @users,
        current_organization: current_organization
      )
    end

    def conditions
      default_conditions = [
        [
          "#{Organization.table_name}.id = :organization_id",
          "#{Organization.table_name}.id IS NULL"
        ].join(' OR '),
        { organization_id: current_organization.id }
      ]

      build_search_conditions User, default_conditions
    end
end
