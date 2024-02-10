# frozen_string_literal: true

class UsersController < ApplicationController
  include Users::Finders
  include Users::Params
  include AutoCompleteFor::Tagging

  before_action :auth, :check_privileges
  before_action :check_ldap, only: [:new, :create]
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # * GET /users
  def index
    @users = users

    respond_to do |format|
      format.html
      format.pdf  { redirect_to pdf.relative_path, allow_other_host: true }
      format.csv  { render csv: csv, filename: filename }
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

    redirect_with_notice @user, url: users_url
  end

  # * PATCH /users/1
  def update
    params[:user][:child_ids] ||= []
    params[:user].delete :lock_version if @user == @auth_user

    @user.update user_params

    @user.send_notification_if_necesary if @user.errors.empty?

    redirect_with_notice @user, url: users_url unless performed?
  end

  # * DELETE /users/1
  def destroy
    @user.disable

    redirect_with_notice @user, url: users_url
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

    def csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**options) do |csv|
        csv << users_header_csv

        users_data_csv.each do |data|
          csv << data
        end

        csv << [filter_text]
      end

      "\uFEFF#{csv_str}"
    end

    def users_header_csv
      [
        User.human_attribute_name('user'),
        User.human_attribute_name('name'),
        User.human_attribute_name('last_name'),
        User.human_attribute_name('email'),
        User.human_attribute_name('function'),
        User.human_attribute_name('roles'),
        User.human_attribute_name('manager_id'),
        User.human_attribute_name('children'),
        User.human_attribute_name('enable'),
        User.human_attribute_name('password_changed'),
        User.human_attribute_name('last_access')
      ]
    end

    def users_data_csv
      @users
        .unscope(:limit, :offset)
        .preload(organization_roles: :role)
        .map do |user|
          [
            user.user,
            user.name,
            user.last_name,
            user.email,
            user.function,
            user.roles(@current_organization.id).map(&:name).join('; '),
            user.parent&.full_name,
            user.children.not_hidden.enabled.map(&:full_name).join(' / '),
            I18n.t(user.enable? ? 'label.yes' : 'label.no'),
            user.password_changed ? I18n.l(user.password_changed, format: :minimal) : '-',
            user.last_access ? I18n.l(user.last_access, format: :minimal) : '-'
          ]
        end
    end

    def filter_text
      columns = search_params[:columns]
      query   = User.split_terms_in_query(search_params[:query])

      if columns.present? || query.present?
        filter_columns = columns.map { |c| "#{User.human_attribute_name c}" }
        query          = query.flatten.map { |q| "#{q}" }
        text           = I18n.t 'user.pdf_csv.filtered_by', query: query.to_sentence,
          columns: filter_columns.to_sentence, count: columns.size
      end
    end

    def filename
      I18n.t 'user.pdf_csv.pdf_csv_name'
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
