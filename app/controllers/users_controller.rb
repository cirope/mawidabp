# frozen_string_literal: true

class UsersController < ApplicationController
  include Users::Finders
  include Users::Params
  include AutoCompleteFor::Tagging

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

    notice_users_left

    respond_with @user, location: users_url
  end

  # * PATCH /users/1
  def update
    params[:user][:child_ids] ||= []
    params[:user].delete :lock_version if @user == @auth_user

    update_resource @user, user_params

    @user.send_notification_if_necesary if @user.errors.empty?

    respond_with @user, location: users_url unless performed?
  end

  # * DELETE /users/1
  def destroy
    @user.disable

    respond_with @user, location: users_url
  end

  private

    def users
      scope = if params[:show_hidden].present?
                User.all
              else
                User.not_hidden
              end

      scope.list.include_tags.search(**search_params).order(
        Arel.sql "#{User.quoted_table_name}.#{User.qcn('user')} ASC"
      ).page params[:page]
    end

    def pdf
      UserPdf.create(
        columns:              search_params[:columns],
        query:                User.split_terms_in_query(search_params[:query]),
        users:                @users.except(:limit, :offset),
        current_organization: current_organization
      )
    end

    def check_ldap
      if current_organization.ldap_config && !ENABLE_USER_CREATION_WHEN_LDAP
        redirect_to_login t('message.insufficient_privileges'), :alert
      end
    end

    def notice_users_left
      if (count = Current.group.users_left_count) && count <= 10
        flash[:notice] = t '.correctly_created_with_count', count: count - 1
      end
    end
end
