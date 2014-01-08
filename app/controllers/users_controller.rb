class UsersController < ApplicationController
  before_action :auth, except: [
    :edit_password, :update_password, :new_initial, :create_initial,
    :initial_roles, :reset_password, :send_password_reset
  ]
  before_action :load_privileges
  before_action :check_privileges, except: [
    :user_status, :edit_password, :user_status_without_graph,
    :update_password, :edit_personal_data, :update_personal_data, :new_initial,
    :create_initial, :initial_roles, :reset_password, :send_password_reset
  ]
  before_action :set_user, only: [
    :show, :edit, :update, :destroy, :user_status, :user_status_without_graph, :blank_password,
    :reassignment_edit, :reassignment_update, :release_edit, :release_update
  ]

  layout ->(controller) { controller.request.xhr? ? false : 'application' }

  # Lista los usuarios
  #
  # * GET /users
  # * GET /users.xml
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
        if @users.size == 1 && !@query.blank? && !params[:page]
          redirect_to user_url(@users.first)
        end
      } # index.html.erb
      format.xml  { render xml: @users }
    end
  end

  # Muestra el detalle de un usuario
  #
  # * GET /users/1
  # * GET /users/1.xml
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

  # Muestra el estado de un usuario
  #
  # * GET /users/1/user_status
  # * GET /users/1/user_status.xml
  def user_status
    @title = t 'user.status_title'
    @user = @auth_user if @auth_user.audited?
    @filtered_weaknesses = @user.weaknesses.for_current_organization.finals(false).not_incomplete

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @user }
    end
  end

  def user_status_without_graph
    @title = t 'user.status_title'
    @user = @auth_user if @auth_user.audited?
    @filtered_weaknesses = @user.weaknesses.for_current_organization.finals(false).not_incomplete

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render xml: @user }
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

  # Blanquea la contraseña de un usuario
  #
  # * PATCH /users/blank_password/1
  # * PATCH /users/blank_password/1.xml
  def blank_password
    if @user
      @user.reset_password!(current_organization)
      redirect_to_index t('user.password_reseted', user: @user.user)
    end
  end

  # Formulario para restablecer contraseña
  #
  # * GET /users/reset_password
  # * GET /users/reset_password.xml
  def reset_password
    @title = t 'user.reset_password_title'
  end

  # Envio de correo para restablecer contraseña
  #
  # * POST /users/send_password_reset
  # * POST /users/send_password_reset.xml
  def send_password_reset
    @title = t 'user.reset_password_title'

    @user = find_with_organization(params[:email], :email)

    if @user && !@user.hidden
      @user.reset_password!(current_organization)
      redirect_to_login t('user.password_reset_sended')
    else
      redirect_to reset_password_users_url, notice: t('user.unknown_email')
    end
  end

  # Cambia la contraseña del usuario actual
  #
  # * GET /users/edit_password/1
  # * GET /users/edit_password/1.xml
  def edit_password
    @title = t 'user.change_password_title'

    unless params[:confirmation_hash].blank?
      @auth_user = User.with_valid_confirmation_hash(
        params[:confirmation_hash]).first
      @current_organization = @auth_user.organizations.first if @auth_user
    else
      login_check
    end

    unless @auth_user
      restart_session
      redirect_to_login t('user.confirmation_link_invalid'), :alert
    else
      @auth_user.password = nil
    end
  end

  # Cambia la contraseña del usuario actual
  #
  # * PATCH /users/update_password/1
  # * PATCH /users/update_password/1.xml
  def update_password
    @title = t 'user.change_password_title'

    unless params[:confirmation_hash].blank?
      @auth_user = User.with_valid_confirmation_hash(
        params[:confirmation_hash]).first
      @current_organization = @auth_user.organizations.first if @auth_user
    else
      login_check
    end

    if @auth_user
      @auth_user.password = user_params[:password]
      @auth_user.password_confirmation = user_params[:password_confirmation]

      if @auth_user.valid?
        @auth_user.encrypt_password
        PaperTrail.whodunnit ||= @auth_user.id

        if @auth_user.update(
            password: @auth_user.password,
            password_confirmation: @auth_user.password,
            password_changed: Date.today,
            change_password_hash: nil,
            enable: true,
            failed_attempts: 0,
            last_access: session[:last_access] || Time.now
          )

          restart_session
          redirect_to_login t('user.password_correctly_updated')
        end
      else
        @auth_user.password = @auth_user.password_confirmation = nil
        render action: :edit_password
      end

      @auth_user.password, @auth_user.password_confirmation = nil, nil
    else
      restart_session
      redirect_to_login t('user.confirmation_link_invalid'), :alert
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'user.password_stale_object_error'
    redirect_to edit_password_user_url(@auth_user)
  end

  # Crea un usuario inicial, sólo hace falta un hash válido para autenticarse
  #
  # * GET /users/new_initial/hash=xxxx
  def new_initial
    group = Group.find_by(admin_hash: params[:hash])

    if group && (group.updated_at || group.created_at) >= 3.days.ago.to_time
      @user = User.new

      render layout: 'application_clean'
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
        render action: :new_initial, layout: 'application_clean'
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

  # Reasigna usuarios en las relaciones que mantienen seguimiento y por lo tanto
  # el usuario es notificado de los eventos (como por ejemplo observaciones).
  #
  # * GET /users/reassignment_edit/1
  # * GET /users/reassignment_edit/1.xml
  def reassignment_edit
    @title = t 'user.user_reassignment'
  end

  # Reasigna usuarios en las relaciones que mantienen seguimiento y por lo tanto
  # el usuario es notificado de los eventos (como por ejemplo observaciones).
  #
  # * PATCH /users/reassignment_update/1
  # * PATCH /users/reassignment_update/1.xml
  def reassignment_update
    @title = t 'user.user_reassignment'

    unless params[:user][:id].blank?
      @other = find_with_organization(params[:user][:id], :id)
    end

    options = {
      with_findings: params[:user][:with_findings] == '1',
      with_reviews: params[:user][:with_reviews] == '1'
    }

    if @other && @user.reassign_to(@other, options)
      flash.notice = t('user.user_reassignment_completed')
      redirect_to users_url
    elsif !@other
      @user.errors.add :base, t('user.errors.must_select_a_user')
      render action: :reassignment_edit
    else
      flash.alert = t('user.user_reassignment_failed')
      render action: :reassignment_edit
    end
  end

  # Libera usuarios de las relaciones que mantienen seguimiento y por lo tanto
  # el usuario queda desligado de los eventos (como por ejemplo observaciones).
  #
  # * GET /users/release_edit/1
  # * GET /users/release_edit/1.xml
  def release_edit
    @title = t 'user.user_release'
  end

  # Libera usuarios de las relaciones que mantienen seguimiento y por lo tanto
  # el usuario queda desligado de los eventos (como por ejemplo observaciones).
  #
  # * PATCH /users/release_update/1
  # * PATCH /users/release_update/1.xml
  def release_update
    @title = t 'user.user_release'

    options = {
      with_findings: params[:user][:with_findings] == '1',
      with_reviews: params[:user][:with_reviews] == '1'
    }

    if @user.release_for_all_pending_findings(options)
      flash.notice = t('user.user_release_completed')
      redirect_to users_url
    else
      flash.alert = t('user.user_release_failed')
      render action: :reassignment_edit
    end
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

      parameters[:"user_data_#{i}"] = "%#{Unicode::downcase(t)}%"
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
    # Busca el usuario indicado siempre que pertenezca a la organización. En el
    # caso que no se encuentre (ya sea que no existe un usuario con ese ID o que
    # no pertenece a la organización con la que se autenticó el usuario) devuelve
    # nil.
    # _id_:: ID (campo usuario) del usuario que se quiere recuperar
    def find_with_organization(id, field = :user) #:doc:
      id = field == :id ? id.to_i : id.try(:downcase).try(:strip)
      id_field = field == :id ?
        "#{User.table_name}.#{field}" : "LOWER(#{User.table_name}.#{field})"

      User.includes(:organizations).where(
        [
          "#{id_field} = :id",
          [
            "#{Organization.table_name}.id = :organization_id",
            "#{Organization.table_name}.id IS NULL"
          ].join(' OR ')
        ].map {|c| "(#{c})"}.join(' AND '),
        {:id => id, :organization_id => current_organization.try(:id)}
      ).references(:organizations).first || (find_with_organization(id, :id) unless field == :id)
    end

    def set_user
      @user = User.includes(:organizations).where(
        user: params[:id], "#{Organization.table_name}.id" => current_organization.try(:id)
      ).references(:organizations).first if params[:id].present?
    end

    def user_params
      params.require(:user).permit(
        :user, :name, :last_name, :email, :language, :notes, :resource_id,
        :manager_id, :enable, :logged_in, :password, :hidden, :function,
        :send_notification_email, :lock_version, child_ids: [],
        organization_roles_attributes: [
          :id, :organization_id, :role_id, :_destroy
        ],
        related_user_relations_attributes: [:id, :related_user_id, :_destroy]
      )
    end

    def load_privileges #:nodoc:
      if @action_privileges
        @action_privileges.update(
          auto_complete_for_user: :read,
          roles: :read,
          user_status: :read,
          export_to_pdf: :read,
          blank_password: :modify,
          reassignment_edit: :modify,
          reassignment_update: :modify,
          release_edit: :modify,
          release_update: :modify
        )
      end
    end
end
