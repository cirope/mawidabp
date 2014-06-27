class UsersController < ApplicationController
  include Users::Finders
  include Users::Params

  before_action :auth, except: [:new_initial, :create_initial, :initial_roles]
  before_action :load_privileges
  before_action :check_privileges, except: [
    :edit_personal_data, :update_personal_data, :new_initial, :create_initial,
    :initial_roles
  ]
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # * GET /users
  def index
    @title = t 'user.index_title'
    default_conditions = [
      [
        [
          "#{Organization.table_name}.id = :organization_id",
          "#{Organization.table_name}.id IS NULL"
        ].join(' OR '),
        "#{User.table_name}.group_admin = :boolean_false"
      ].join(' AND '),
      { organization_id: current_organization.id, boolean_false: false }
    ]

    build_search_conditions User, default_conditions

    @users = User.includes(:organizations).where(@conditions).not_hidden.order(
      "#{User.table_name}.user ASC"
    ).references(:organizations).page(params[:page])

    respond_to do |format|
      format.html {
        if @users.count == 1 && !@query.blank? && !params[:page]
          redirect_to user_url(@users.first)
        end
      }
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

  # Lista los roles de la organización indicada
  #
  # * GET /users/roles/1.json
  def roles
    organization = Organization.find(params[:id])
    roles = Role.list_by_organization_and_group organization, organization.group

    respond_to do |format|
      format.json { render json: roles.map { |r| [r.name, r.id] } }
    end
  end

  # Crea un usuario inicial, sólo hace falta un hash válido para autenticarse
  #
  # * GET /users/new_initial/hash=xxxx
  def new_initial
    group = Group.find_by(admin_hash: params[:hash])

    if group && (group.updated_at || group.created_at) >= 3.days.ago.to_time
      @user = User.new

      render layout: 'clean'
    else
      restart_session
      redirect_to_login t('message.must_be_authenticated'), :alert
    end
  end

  # Crea un usuario inicial, sólo hace falta un hash válido para autenticarse
  #
  # * POST /users/create_initial
  def create_initial
    group = Group.find_by(admin_hash: params[:hash])

    if group && (group.updated_at || group.created_at) >= 3.days.ago.to_time
      @user = User.new(user_params)

      if @user.save && group.update(admin_hash: nil)
        @user.send_welcome_email
        restart_session
        redirect_to_login t('user.correctly_created')
      else
        render action: :new_initial, layout: 'clean'
      end
    else
      restart_session
      redirect_to_login t('message.must_be_authenticated'), :alert
    end
  end

  # Lista los roles de la organización indicada
  #
  # * GET /users/initial_roles/1.json
  def initial_roles
    group = Group.find_by(admin_hash: params[:hash])

    if group && (group.updated_at || group.created_at) >= 3.days.ago.to_time
      roles = Role.where organization_id: params[:id]

      respond_to do |format|
        format.json { render json: roles.map { |r| [r.name, r.id] } }
      end
    else
      restart_session
      redirect_to_login t('message.must_be_authenticated'), :alert
    end
  end

  # Cambia los datos del usuario actual
  #
  # * GET /users/edit_personal_data/1
  # * GET /users/edit_personal_data/1.xml
  def edit_personal_data
    @title = t 'user.change_personal_data'
  end

  # Cambia los datos del usuario actual
  #
  # * PATCH /users/update_personal_data/1
  # * PATCH /users/update_personal_data/1.xml
  def update_personal_data
    @title = t 'user.change_personal_data'

    attributes = {
      name: params[:user][:name],
      last_name: params[:user][:last_name],
      language: params[:user][:language],
      email: params[:user][:email],
      function: params[:user][:function]
    }

    @auth_user.is_an_important_change = false

    if @auth_user.update(attributes)
      flash.notice = t 'user.correctly_updated'
    end

    render action: :edit_personal_data

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'user.password_stale_object_error'
    redirect_to edit_personal_data_user_url(@auth_user)
  end

  # Lista las usuarios
  #
  # * GET /users/export_to_pdf
  def export_to_pdf
    default_conditions = {
      "#{Organization.table_name}.id" => current_organization.id
    }

    build_search_conditions User, default_conditions

    users = User.includes(:organizations).where(@conditions).order(
      "#{User.table_name}.user ASC"
    ).references(:organizations)

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header current_organization
    pdf.add_title t('user.index_title')

    column_order = [['user', 10], ['name', 10], ['last_name', 10],
      ['email', 17], ['function', 14], ['roles', 10], ['enable', 8],
      ['password_changed', 10], ['last_access', 11]]
    column_data, column_headers, column_widths = [], [], []

    column_order.each do |col_name, col_width|
      column_headers << User.human_attribute_name(col_name)
      column_widths << pdf.percent_width(col_width)
    end

    users.each do |user|
      column_data << [
        "<b>#{user.user}</b>",
        user.name,
        user.last_name,
        user.email,
        user.function,
        user.roles.map(&:name).join('; '),
        t(user.enable? ? 'label.yes' : 'label.no'),
        user.password_changed ?
          l(user.password_changed, format: :minimal) : '-',
        user.last_access ?
          l(user.last_access, format: :minimal) : '-'
      ]
    end

    unless @columns.blank? || @query.blank?
      pdf.move_down PDF_FONT_SIZE
      filter_columns = @columns.map do |c|
        "<b>#{User.human_attribute_name(c)}</b>"
      end

      pdf.text t('user.pdf.filtered_by',
        query: @query.map {|q| "<b>#{q}</b>"}.join(', '),
        columns: filter_columns.to_sentence, count: @columns.size),
        font_size: (PDF_FONT_SIZE * 0.75).round,
        inline_format: true
    end

    pdf.move_down PDF_FONT_SIZE

    unless column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    pdf.move_down PDF_FONT_SIZE
    pdf.text t('user.pdf.users_count', count: users.size)

    pdf_name = t 'user.pdf.pdf_name'

    pdf.custom_save_as(pdf_name, User.table_name)

    redirect_to Prawn::Document.relative_path(pdf_name, User.table_name)
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
          auto_complete_for_user: :read,
          roles: :read,
          export_to_pdf: :read
        )
      end
    end
end
