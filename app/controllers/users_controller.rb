# encoding: utf-8
# =Controlador de usuarios
#
# Lista, muestra, crea, modifica y elimina usuarios (#User). Además controla el
# ingreso al sistema, permite blanquear la contraseña, cambiarla, etc. y
# salir de la aplicación de manera segura.
class UsersController < ApplicationController
  before_filter :auth, :except => [
    :login, :create_session, :edit_password, :update_password, :new_initial,
    :create_initial, :initial_roles, :reset_password, :send_password_reset
  ]
  before_filter :load_privileges
  before_filter :check_privileges, :except => [
    :login, :create_session, :logout, :user_status, :edit_password, :user_status_without_graph,
    :update_password, :edit_personal_data, :update_personal_data, :new_initial,
    :create_initial, :initial_roles, :reset_password, :send_password_reset
  ]
  layout proc { |controller|
    use_clean = [
      'login', 'create_session', 'reset_password', 'send_password_reset'
    ].include?(controller.action_name)

    controller.request.xhr? ? false : (use_clean ? 'clean' : 'application')
  }
  hide_action :find_with_organization, :load_privileges

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
      { :organization_id => @auth_organization.id, :boolean_false => false }
    ]

    build_search_conditions User, default_conditions

    @users = User.includes(:organizations).where(@conditions).not_hidden.order(
      "#{User.table_name}.user ASC"
    ).paginate(:page => params[:page], :per_page => APP_LINES_PER_PAGE)

    respond_to do |format|
      format.html {
        if @users.size == 1 && !@query.blank? && !params[:page]
          redirect_to user_url(@users.first)
        end
      } # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # Muestra el detalle de un usuario
  #
  # * GET /users/1
  # * GET /users/1.xml
  def show
    @title = t 'user.show_title'
    @user = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
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
      format.xml  { render :xml => @user }
    end
  end

  # Recupera los datos para modificar un usuario
  #
  # * GET /users/1/edit
  def edit
    @title = t 'user.edit_title'
    @user = find_with_organization(params[:id])
  end

  # Crea un nuevo usuario siempre que cumpla con las validaciones.
  #
  # * POST /users
  # * POST /users.xml
  def create
    @title = t 'user.new_title'
    @user = User.new(params[:user])
    @user.roles.each {|r| r.inject_auth_privileges(@auth_privileges)}

    respond_to do |format|
      if @user.save
        @user.send_welcome_email
        flash.notice = t 'user.correctly_created'
        format.html { redirect_to(users_url) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        @user.password = @user.password_confirmation = nil
        format.html { render :action => :new }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un usuario siempre que cumpla con las
  # validaciones.
  #
  # * PUT /users/1
  # * PUT /users/1.xml
  def update
    @title = t 'user.edit_title'
    @user = find_with_organization(params[:id])
    params[:user][:last_access] = nil if @user.expired?
    params[:user][:child_ids] ||= []
    # Para permitir al usuario actualmente autenticado modificar sus datos
    if @user == @auth_user
      params[:user].delete :lock_version
    end

    respond_to do |format|
      if @user.update(params[:user])
        @user.send_notification_if_necesary
        flash.notice = t 'user.correctly_updated'
        format.html { redirect_to(users_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
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
    @user = find_with_organization(params[:id])

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
    @user = @auth_user.audited? ?
      @auth_user : find_with_organization(params[:id])
    @filtered_weaknesses = @user.weaknesses.for_current_organization.finals(false).not_incomplete

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  def user_status_without_graph
    @title = t 'user.status_title'
    @user = @auth_user.audited? ?
      @auth_user : find_with_organization(params[:id])
    @filtered_weaknesses = @user.weaknesses.for_current_organization.finals(false).not_incomplete

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # Lista los roles de la organización indicada
  #
  # * GET /users/roles/1.json
  def roles
    organization = Organization.find(params[:id])
    roles = Role.list_by_organization_and_group organization, organization.group

    respond_to do |format|
      format.json { render :json => roles.map { |r| [r.name, r.id] } }
    end
  end

  # Realiza la autenticación de los usuarios.
  #
  # * GET /users/login
  def login
    auth_user = User.find(session[:user_id]) if session[:user_id]

    if auth_user && session[:organization_id]
      auth_organization = Organization.find(session[:organization_id])
      GlobalModelConfig.current_organization_id = auth_organization.try :id
    end

    if auth_user.try(:is_enable?) && auth_user.logged_in?
      redirect_to :controller => :welcome
    else
      @title = t 'user.login_title'
      @user = User.new
      organization_prefix = request.subdomains.first
      @group_admin_mode = organization_prefix == APP_ADMIN_PREFIX

      @organization = Organization.find_by_prefix(organization_prefix)
    end
  end

  # Realiza la autenticación de los usuarios.
  #
  # * POST /users/create_session
  def create_session
    @title = t 'user.login_title'
    @user = User.new(params[:user])
    organization_prefix = request.subdomains.first
    @group_admin_mode = organization_prefix == APP_ADMIN_PREFIX

    @organization = Organization.find_by_prefix(organization_prefix)

    GlobalModelConfig.current_organization_id = @organization.try :id

    if @organization || @group_admin_mode
      conditions = ["LOWER(#{User.table_name}.user) = :user"]
      parameters = {:user => @user.user.downcase}

      if @group_admin_mode
        conditions << "#{User.table_name}.group_admin = :true"
        parameters[:true] = true
      else
        conditions << "#{Organization.table_name}.id = :organization_id"
        parameters[:organization_id] = @organization.id
      end

      auth_user = User.includes(:organizations).where(
        conditions.join(' AND '), parameters
      ).first(:readonly => false)

      @user.salt = auth_user.salt if auth_user
      @user.encrypt_password

      if !@group_admin_mode && auth_user && auth_user.must_change_the_password?
        session[:user_id] = auth_user.id
        flash.notice ||= t 'message.must_change_the_password'
        session[:go_to] = edit_password_user_url(auth_user)
      elsif !@group_admin_mode && auth_user && auth_user.expired?
        auth_user.is_an_important_change = false
        auth_user.update_attribute :enable, false
      end

      if !@group_admin_mode && auth_user && auth_user.is_enable? && !auth_user.hidden &&
          @user.password_was_encrypted && auth_user.password == @user.password
        record = LoginRecord.new(
          :user => auth_user,
          :organization => @organization,
          :request => request
        )

        if record.save
          days_for_password_expiration =
            auth_user.days_for_password_expiration

          if days_for_password_expiration
            flash.notice = t(days_for_password_expiration >= 0 ?
                'message.password_expire_in_x' :
                'message.password_expired_x_days_ago',
              :count => days_for_password_expiration.abs)
          end

          unless auth_user.allow_concurrent_access?
            auth_user = nil
            @user = User.new
            flash.alert = t 'message.you_are_already_logged'

            render :action => :login
          end

          if auth_user
            session[:last_access] = Time.now
            auth_user.logged_in!(session[:last_access])
            session[:user_id] = auth_user.id
            session[:organization_id] = @organization.id
            if poll = auth_user.first_pending_poll
              flash.notice = t 'poll.must_answer_poll'
              go_to = edit_poll_url(poll, :token => poll.access_token, :layout => 'application_clean')
            else
              go_to = session[:go_to] || { :controller => :welcome }
            end
            session[:go_to], session[:record_id] = nil, record.id

            redirect_to go_to
          end
        end
      elsif @group_admin_mode && auth_user.try(:is_group_admin?) &&
          auth_user.password == @user.password
        session[:last_access] = Time.now
        auth_user.logged_in!(session[:last_access])
        session[:user_id] = auth_user.id

        redirect_to :controller => :groups, :action => :index
      else
        if (user = User.find_by_user(@user.user))
          ErrorRecord.create(:user => user, :organization => @organization,
            :request => request, :error_type => :on_login)

          user.failed_attempts += 1
          max_attempts = @group_admin_mode ?
            3 : user.get_parameter(:security_attempts_count).to_i

          if (max_attempts != 0 && user.failed_attempts >= max_attempts) &&
              user.is_enable?
            user.enable = false

            ErrorRecord.create(:user => user, :organization => @organization,
              :request => request, :error_type => :user_disabled)
          end

          user.is_an_important_change = false
          user.save(:validate => false)
        else
          ErrorRecord.create(:user_name => @user.user,
            :organization => @organization, :request => request,
            :error_type => :on_login)
        end

        @user.password = nil
        flash.alert = t 'message.invalid_user_or_password'
        render :action => :login
      end
    else
      render :action => :login unless session[:user_id]
    end
  end

  # Blanquea la contraseña de un usuario
  #
  # * PUT /users/blank_password/1
  # * PUT /users/blank_password/1.xml
  def blank_password
    @user = find_with_organization(params[:id])

    if @user
      @user.reset_password!(@auth_organization)

      redirect_to_index t('user.password_reseted', :user => @user.user)
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
    @auth_organization = Organization.find_by_prefix(request.subdomains.first)
    @user = find_with_organization(params[:email], :email)

    if @user && !@user.hidden
      @user.reset_password!(@auth_organization)
      redirect_to_login t('user.password_reset_sended')
    else
      redirect_to reset_password_users_url, :notice => t('user.unknown_email')
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
      @auth_organization = @auth_user.organizations.first if @auth_user
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
  # * PUT /users/update_password/1
  # * PUT /users/update_password/1.xml
  def update_password
    @title = t 'user.change_password_title'

    unless params[:confirmation_hash].blank?
      @auth_user = User.with_valid_confirmation_hash(
        params[:confirmation_hash]).first
      @auth_organization = @auth_user.organizations.first if @auth_user
    else
      login_check
    end

    if @auth_user
      @auth_user.password = params[:user][:password]
      @auth_user.password_confirmation = params[:user][:password_confirmation]

      if @auth_user.valid?
        @auth_user.encrypt_password
        PaperTrail.whodunnit ||= @auth_user.id

        if @auth_user.update(
            :password => @auth_user.password,
            :password_confirmation => @auth_user.password,
            :password_changed => Date.today,
            :change_password_hash => nil,
            :enable => true,
            :failed_attempts => 0,
            :last_access => session[:last_access] || Time.now
          )

          restart_session
          redirect_to_login t('user.password_correctly_updated')
        end
      else
        @auth_user.password = @auth_user.password_confirmation = nil
        render :action => :edit_password
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
    group = Group.find_by_admin_hash(params[:hash])

    if group && (group.updated_at || group.created_at) >= 3.days.ago.to_time
      @user = User.new

      render :layout => 'application_clean'
    else
      restart_session
      redirect_to_login t('message.must_be_authenticated'), :alert
    end
  end

  # Crea un usuario inicial, sólo hace falta un hash válido para autenticarse
  #
  # * POST /users/create_initial
  def create_initial
    group = Group.find_by_admin_hash(params[:hash])

    if group && (group.updated_at || group.created_at) >= 3.days.ago.to_time
      @user = User.new(params[:user])

      if @user.save && group.update_attribute(:admin_hash, nil)
        @user.send_welcome_email
        restart_session
        redirect_to_login t('user.correctly_created')
      else
        render :action => :new_initial, :layout => 'application_clean'
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
    group = Group.find_by_admin_hash(params[:hash])

    if group && (group.updated_at || group.created_at) >= 3.days.ago.to_time
      roles = Role.find_all_by_organization_id params[:id]

      respond_to do |format|
        format.json { render :json => roles.map { |r| [r.name, r.id] } }
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
  # * PUT /users/update_personal_data/1
  # * PUT /users/update_personal_data/1.xml
  def update_personal_data
    @title = t 'user.change_personal_data'

    attributes = {
      :name => params[:user][:name],
      :last_name => params[:user][:last_name],
      :language => params[:user][:language],
      :email => params[:user][:email],
      :function => params[:user][:function]
    }

    @auth_user.is_an_important_change = false

    if @auth_user.update(attributes)
      flash.notice = t 'user.correctly_updated'
    end

    render :action => :edit_personal_data

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
    @user = find_with_organization(params[:id])
  end

  # Reasigna usuarios en las relaciones que mantienen seguimiento y por lo tanto
  # el usuario es notificado de los eventos (como por ejemplo observaciones).
  #
  # * PUT /users/reassignment_update/1
  # * PUT /users/reassignment_update/1.xml
  def reassignment_update
    @title = t 'user.user_reassignment'
    @user = find_with_organization(params[:id])

    unless params[:user][:id].blank?
      @other = find_with_organization(params[:user][:id], :id)
    end

    options = {
      :with_findings => params[:user][:with_findings] == '1',
      :with_reviews => params[:user][:with_reviews] == '1'
    }

    if @other && @user.reassign_to(@other, options)
      flash.notice = t('user.user_reassignment_completed')
      redirect_to users_url
    elsif !@other
      @user.errors.add :base, t('user.errors.must_select_a_user')
      render :action => :reassignment_edit
    else
      flash.alert = t('user.user_reassignment_failed')
      render :action => :reassignment_edit
    end
  end

  # Libera usuarios de las relaciones que mantienen seguimiento y por lo tanto
  # el usuario queda desligado de los eventos (como por ejemplo observaciones).
  #
  # * GET /users/release_edit/1
  # * GET /users/release_edit/1.xml
  def release_edit
    @title = t 'user.user_release'
    @user = find_with_organization(params[:id])
  end

  # Libera usuarios de las relaciones que mantienen seguimiento y por lo tanto
  # el usuario queda desligado de los eventos (como por ejemplo observaciones).
  #
  # * PUT /users/release_update/1
  # * PUT /users/release_update/1.xml
  def release_update
    @title = t 'user.user_release'
    @user = find_with_organization(params[:id])

    options = {
      :with_findings => params[:user][:with_findings] == '1',
      :with_reviews => params[:user][:with_reviews] == '1'
    }

    if @user.release_for_all_pending_findings(options)
      flash.notice = t('user.user_release_completed')
      redirect_to users_url
    else
      flash.alert = t('user.user_release_failed')
      render :action => :reassignment_edit
    end
  end

  # Cierra la sesión del usuario y registra su egreso
  #
  # * GET /users/logout/1
  # * GET /users/logout/1.xml
  def logout
    if session[:record_id] && LoginRecord.exists?(session[:record_id])
      LoginRecord.find(session[:record_id]).end!
    end

    @auth_user.logout! if @auth_user

    restart_session
    redirect_to_login t('message.session_closed_correctly')
  end

  # Lista las usuarios
  #
  # * GET /users/export_to_pdf
  def export_to_pdf
    default_conditions = {
      "#{Organization.table_name}.id" => @auth_organization.id
    }

    build_search_conditions User, default_conditions

    users = User.includes(:organizations).where(@conditions).order(
      "#{User.table_name}.user ASC"
    )

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization
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
          l(user.password_changed, :format => :minimal) : '-',
        user.last_access ?
          l(user.last_access, :format => :minimal) : '-'
      ]
    end

    unless @columns.blank? || @query.blank?
      pdf.move_down PDF_FONT_SIZE
      filter_columns = @columns.map do |c|
        "<b>#{User.human_attribute_name(c)}</b>"
      end

      pdf.text t('user.pdf.filtered_by',
        :query => @query.map {|q| "<b>#{q}</b>"}.join(', '),
        :columns => filter_columns.to_sentence, :count => @columns.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round,
        :inline_format => true
    end

    pdf.move_down PDF_FONT_SIZE

    unless column_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        table_options = pdf.default_table_options(column_widths)

        pdf.table(column_data.insert(0, column_headers), table_options) do
          row(0).style(
            :background_color => 'cccccc',
            :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    pdf.move_down PDF_FONT_SIZE
    pdf.text t('user.pdf.users_count', :count => users.size)

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
      :organization_id => @auth_organization.id,
      :self_id => params[:user_id]
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
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order(
      ["#{User.table_name}.last_name ASC", "#{User.table_name}.name ASC"]
    ).limit(10)

    respond_to do |format|
      format.json { render :json => @users }
    end
  end

  private

  # Busca el usuario indicado siempre que pertenezca a la organización. En el
  # caso que no se encuentre (ya sea que no existe un usuario con ese ID o que
  # no pertenece a la organización con la que se autenticó el usuario) devuelve
  # nil.
  # _id_::  ID (campo usuario) del usuario que se quiere recuperar
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
      {:id => id, :organization_id => @auth_organization.id}
    ).first(
      :readonly => false
    ) || (find_with_organization(id, :id) unless field == :id)
  end

  def load_privileges #:nodoc:
    if @action_privileges
      @action_privileges.update(
        :auto_complete_for_user => :read,
        :roles => :read,
        :user_status => :read,
        :export_to_pdf => :read,
        :blank_password => :modify,
        :reassignment_edit => :modify,
        :reassignment_update => :modify,
        :release_edit => :modify,
        :release_update => :modify
      )
    end
  end
end
