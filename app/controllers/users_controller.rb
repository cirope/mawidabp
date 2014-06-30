class UsersController < ApplicationController
  include Users::Finders
  include Users::Params

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # * GET /users
  def index
    @title = t 'user.index_title'
    @users = users

    respond_to do |format|
      format.html { redirect_to user_url(@users.first) if one_result?  }
      format.pdf  { redirect_to pdf.relative_path }
    end
  end

  # * GET /users/1
  def show
    @title = t 'user.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @user }
    end
  end

  # Permite ingresar los datos para crear un nuevo usuario
  #
  # * GET /users/new
  # * GET /users/new.xml
  def new
    @title = t 'user.new_title'
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render xml: @user }
    end
  end

  # Recupera los datos para modificar un usuario
  #
  # * GET /users/1/edit
  def edit
    @title = t 'user.edit_title'
  end

  # Crea un nuevo usuario siempre que cumpla con las validaciones.
  #
  # * POST /users
  # * POST /users.xml
  def create
    @title = t 'user.new_title'
    @user = User.new(user_params)
    @user.roles.each {|r| r.inject_auth_privileges(@auth_privileges)}

    respond_to do |format|
      if @user.save
        @user.send_welcome_email
        flash.notice = t 'user.correctly_created'
        format.html { redirect_to(users_url) }
        format.xml  { render xml: @user, status: :created, location: @user }
      else
        @user.password = @user.password_confirmation = nil
        format.html { render action: :new }
        format.xml  { render xml: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un usuario siempre que cumpla con las
  # validaciones.
  #
  # * PATCH /users/1
  # * PATCH /users/1.xml
  def update
    @title = t 'user.edit_title'
    params[:user][:last_access] = nil if @user.expired?
    params[:user][:child_ids] ||= []
    # Para permitir al usuario actualmente autenticado modificar sus datos
    if @user == @auth_user
      params[:user].delete :lock_version
    end

    respond_to do |format|
      if @user.update(user_params)
        @user.send_notification_if_necesary
        flash.notice = t 'user.correctly_updated'
        format.html { redirect_to(users_url) }
        format.xml  { head :ok }
      else
        format.html { render action: :edit }
        format.xml  { render xml: @user.errors, status: :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'user.stale_object_error'
    redirect_to edit_user_url(@user)
  end

  # Elimina un usuario
  #
  # * DELETE /users/1
  # * DELETE /users/1.xml
  def destroy
    unless @user.disable!
      flash.alert = @user.errors.full_messages.join(APP_ENUM_SEPARATOR)
    else
      flash.notice = t 'user.correctly_disabled'
    end

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
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
