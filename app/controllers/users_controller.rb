require 'pdf/simpletable'

# =Controlador de usuarios
#
# Lista, muestra, crea, modifica y elimina usuarios (#User). Además controla el
# ingreso al sistema, permite blanquear la contraseña, cambiarla, etc. y
# salir de la aplicación de manera segura.
class UsersController < ApplicationController
  before_filter :auth, :except => [:login, :change_password]
  before_filter :load_privileges
  before_filter :check_privileges,
    :except => [:login, :logout, :change_password, :change_personal_data]
  layout proc { |controller|
    controller.request.xhr? ? false :
      (controller.action_name == 'login' ? 'clean' : 'application')
  }
  hide_action :find_with_organization, :load_privileges

  # Lista las usuarios
  #
  # * GET /users
  # * GET /users.xml
  def index
    @title = t :'user.index_title'
    default_conditions = [
      [
        "#{Organization.table_name}.id = :organization_id",
        "#{Organization.table_name}.id IS NULL"
      ].join(' OR '),
      {:organization_id => @auth_organization.id}
    ]

    build_search_conditions User, default_conditions

    @users = User.paginate(:page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => :organizations,
      :conditions => @conditions,
      :order => "#{User.table_name}.user ASC")

    respond_to do |format|
      format.html {
        if @users.size == 1 && !@query.blank?
          redirect_to edit_user_path(@users.first)
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
    @title = t :'user.show_title'
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
    @title = t :'user.new_title'
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
    @title = t :'user.edit_title'
    @user = find_with_organization(params[:id])
  end

  # Crea un nuevo usuario siempre que cumpla con las validaciones.
  #
  # * POST /users
  # * POST /users.xml
  def create
    @title = t :'user.new_title'
    @user = User.new(params[:user])
    @user.roles.each {|r| r.inject_auth_privileges(@auth_privileges)}
    
    respond_to do |format|
      if @user.save
        @user.send_welcome_email
        flash[:notice] = t :'user.correctly_created'
        format.html { redirect_to(users_path) }
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
    @title = t :'user.edit_title'
    @user = find_with_organization(params[:id])
    params[:user][:last_access] = nil if @user.expired?
    # Para permitir al usuario actualmente autenticado modificar sus datos
    if @user == @auth_user
      params[:user].delete :lock_version
    end

    respond_to do |format|
      if @user.update_attributes(params[:user])
        @user.send_notification_if_necesary
        flash[:notice] = t :'user.correctly_updated'
        format.html { redirect_to(users_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash[:notice] = t :'user.stale_object_error'
    redirect_to edit_user_url(@user)
  end

  # Marca como eliminada un usuario
  #
  # * DELETE /users/1
  # * DELETE /users/1.xml
  def destroy
    @user = find_with_organization(params[:id])
    
    unless @user.disable!
      flash[:notice] = @user.errors.full_messages.join(APP_ENUM_SEPARATOR)
    else
      flash[:notice] = t :'user.correctly_disabled'
    end

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

  # Lista los informes del periodo indicado
  #
  # * GET /users/roles/1.json
  def roles
    roles = Role.find_all_by_organization_id params[:id]

    respond_to do |format|
      format.json  { render :json => roles.map { |r| [r.name, r.id] }}
    end
  end

  # Realiza la autenticación de los usuarios.
  #
  # * GET /users/login
  # * POST /users/login
  def login
    auth_user = User.find(session[:user_id]) if session[:user_id]
    
    if auth_user && session[:organization_id]
      auth_organization = Organization.find(session[:organization_id])
      GlobalModelConfig.current_organization_id = auth_organization.try :id
    end
    
    if auth_user.try(:is_enable?) && auth_user.logged_in?
      redirect_to :controller => :welcome
    else
      @title = t :'user.login_title'
      organization_prefix = request.subdomains.first
      show_default_organization_warning = false

      if organization_prefix == 'www' || !organization_prefix
        organization_prefix = APP_DEFAULT_ORGANIZATION
        show_default_organization_warning = true
      end

      @organization = Organization.find_by_prefix(organization_prefix)

      GlobalModelConfig.current_organization_id = @organization.try :id

      if @organization && params[:user]
        @user = User.new(params[:user])

        auth_user = User.first(
          :joins => :organizations,
          :conditions => {
            "#{User.table_name}.user" => @user.user,
            "#{Organization.table_name}.id" => @organization.id
          },
          :readonly => false
        )

        @user.salt = auth_user.salt if auth_user
        @user.encrypt_password

        if auth_user && auth_user.must_change_the_password?
          session[:user_id] = auth_user.id
          flash[:notice] ||= t :'message.must_change_the_password'
          session[:go_to] = change_password_user_url(auth_user)
        elsif auth_user && auth_user.expired?
          auth_user.is_an_important_change = false
          auth_user.update_attribute :enable, false
        end

        if auth_user && auth_user.is_enable? && @user.password_was_encrypted &&
            auth_user.password == @user.password
          record = LoginRecord.new(
            :user => auth_user,
            :organization => @organization,
            :request => request
          )

          if record.save
            days_for_password_expiration =
              auth_user.days_for_password_expiration

            if days_for_password_expiration
              flash[:notice] = t(days_for_password_expiration >= 0 ?
                  :'message.password_expire_in_x' :
                  :'message.password_expired_x_days_ago',
                :count => days_for_password_expiration.abs)
            end

            unless auth_user.allow_concurrent_access?
              flash[:notice] ||= t :'message.you_are_already_logged'
              auth_user = nil
              @user = User.new
            end

            if auth_user
              session[:last_access] = Time.now
              auth_user.logged_in!(session[:last_access])
              session[:user_id] = auth_user.id
              session[:organization_id] = @organization.id
              go_to = session[:go_to] || {:controller => :welcome}
              session[:go_to], session[:record_id] = nil, record.id

              redirect_to go_to
            end
          end
        elsif
          if (user = User.find_by_user(@user.user))
            ErrorRecord.create(:user => user, :organization => @organization,
              :request => request, :error_type => :on_login)

            user.failed_attempts += 1
            max_attempts = user.get_parameter(:security_attempts_count).to_i

            if (max_attempts != 0 && user.failed_attempts >= max_attempts) &&
                user.is_enable?
              user.enable = false

              ErrorRecord.create(:user => user, :organization => @organization,
                :request => request, :error_type => :user_disabled)
            end

            user.is_an_important_change = false
            user.save
          else
            ErrorRecord.create(:user_name => @user.user,
              :organization => @organization, :request => request,
              :error_type => :on_login)
          end

          @user.password = nil
          flash[:notice] = t :'message.invalid_user_or_password'
        end
      else
        @user = User.new
        if show_default_organization_warning && @organization
          flash[:notice] ||= t(:'message.default_organization_selected',
            :organization => @organization.name)
        end
      end
    end
  end

  # Blanquea la contraseña de un usuario
  #
  # * PUT /users/blank_password/1
  # * PUT /users/blank_password/1.xml
  def blank_password
    @user = find_with_organization(params[:id])

    if @user
      old_password = OldPassword.new(
        :password => @user.password,
        :user => @user
      )

      if old_password.save
        @user.blank_password!(@auth_organization)
        
        redirect_to_index t(:'user.password_reseted', :user => @user.user)
      end
    end
  end

  # Cambia la contraseña del usuario actual
  #
  # * GET /users/change_password/1
  # * GET /users/change_password/1.xml
  # * PUT /users/change_password/1
  # * PUT /users/change_password/1.xml
  def change_password
    @title = t :'user.change_password_title'
    
    unless params[:confirmation_hash].blank?
      @auth_user = User.with_valid_confirmation_hash(
        params[:confirmation_hash]).first
      @auth_organization = @auth_user.organizations.first if @auth_user
    else
      login_check
    end
    
    if @auth_user && params[:user]
      @auth_user.password = params[:user][:password]
      @auth_user.password_confirmation = params[:user][:password_confirmation]

      if @auth_user.valid?
        @auth_user.encrypt_password
        @auth_user.is_an_important_change = false

        if @auth_user.update_attributes(
            :password => @auth_user.password,
            :password_confirmation => @auth_user.password,
            :password_changed => Date.today,
            :change_password_hash => nil,
            :last_access => session[:last_access] || Time.now
          )
          
          restart_session
          redirect_to_login t(:'user.password_correctly_updated')
        end
      end

      @auth_user.password, @auth_user.password_confirmation = nil, nil
    elsif @auth_user
      @auth_user.password = nil
    else
      restart_session
      redirect_to_login t(:'user.confirmation_link_invalid')
    end

  rescue ActiveRecord::StaleObjectError
    flash[:notice] = t :'user.password_stale_object_error'
    redirect_to change_password_user_url(@auth_user)
  end

  # Cambia los datos del usuario actual
  #
  # * GET /users/change_personal_data/1
  # * GET /users/change_personal_data/1.xml
  # * PUT /users/change_personal_data/1
  # * PUT /users/change_personal_data/1.xml
  def change_personal_data
    @title = t :'user.change_personal_data'

    if params[:user]
      attributes = {
        :name => params[:user][:name],
        :last_name => params[:user][:last_name],
        :language => params[:user][:language],
        :email => params[:user][:email],
        :function => params[:user][:function]
      }

      @auth_user.is_an_important_change = false

      if @auth_user.update_attributes(attributes)
        I18n.locale = @auth_user.language
        flash[:notice] = t :'user.correctly_updated'
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash[:notice] = t :'user.password_stale_object_error'
    redirect_to change_personal_data_user_url(@auth_user)
  end

  # Reasigna usuarios en las relaciones que mantienen seguimiento y por lo tanto
  # el usuario es notificado de los eventos (como por ejemplo observaciones).
  #
  # * GET /users/user_reassignment/1
  # * GET /users/user_reassignment/1.xml
  # * PUT /users/user_reassignment/1
  # * PUT /users/user_reassignment/1.xml
  def user_reassignment
    @title = t :'user.user_reassignment'
    @user = find_with_organization(params[:id])

    if params[:user]
      unless params[:user][:id].blank?
        @other = find_with_organization(params[:user][:id], 'id')
      end
      
      options = {
        :with_findings => params[:user][:with_findings] == '1',
        :with_reviews => params[:user][:with_reviews] == '1'
      }

      if @other && @user.reassign_to(@other, options)
        flash[:notice] = t(:'user.user_reassignment_completed')
        redirect_to users_path
      elsif !@other
        @user.errors.add_to_base t(:'user.errors.must_select_a_user')
      else
        flash[:notice] = t(:'user.user_reassignment_failed')
      end
    end
  end

  # Libera usuarios de las relaciones que mantienen seguimiento y por lo tanto
  # el usuario queda desligado de los eventos (como por ejemplo observaciones).
  #
  # * GET /users/user_release/1
  # * GET /users/user_release/1.xml
  # * PUT /users/user_release/1
  # * PUT /users/user_release/1.xml
  def user_release
    @title = t :'user.user_release'
    @user = find_with_organization(params[:id])

    if params[:user]
      options = {
        :with_findings => params[:user][:with_findings] == '1',
        :with_reviews => params[:user][:with_reviews] == '1'
      }

      if @user.release_for_all_pending_findings(options)
        flash[:notice] = t(:'user.user_release_completed')
        redirect_to users_path
      else
        flash[:notice] = t(:'user.user_release_failed')
      end
    end
  end

  # Cierra la sesión del usuario y registra su egreso
  #
  # * GET /users/logout/1
  # * GET /users/logout/1.xml
  def logout
    if LoginRecord.exists?(session[:record_id])
      LoginRecord.find(session[:record_id]).end!
    end

    @auth_user.logout! if @auth_user
    
    restart_session
    redirect_to_login t(:'message.session_closed_correctly')
  end

  # Lista las usuarios
  #
  # * GET /users/export_to_pdf
  def export_to_pdf
    default_conditions = {
      "#{Organization.table_name}.id" => @auth_organization.id
    }

    build_search_conditions User, default_conditions
    
    users = User.all(
      :joins => :organizations,
      :conditions => @conditions,
      :order => "#{User.table_name}.user ASC")

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization
    pdf.add_title t(:'user.index_title')

    column_order = [['user', 10], ['name', 10], ['last_name', 10],
      ['email', 17], ['function', 14], ['roles', 10], ['enable', 8],
      ['password_changed', 10], ['last_access', 11]]
    columns = {}
    column_data = []

    column_order.each do |col_name, col_with|
      columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
        c.heading = User.human_attribute_name col_name
        c.width = pdf.percent_width col_with
      end
    end

    users.each do |user|
      column_data << {
        'user' => "<b>#{user.user}</b>".to_iso,
        'name' => user.name.to_iso,
        'last_name' => user.last_name.to_iso,
        'email' => user.email.try(:to_iso),
        'function' => user.function.try(:to_iso),
        'roles' => user.roles.map(&:name).join('; ').to_iso,
        'enable' => t(user.enable? ? :'label.yes' : :'label.no').to_iso,
        'password_changed' => user.password_changed ?
          l(user.password_changed, :format => :minimal).to_iso : '-',
        'last_access' => user.last_access ?
          l(user.last_access, :format => :minimal).to_iso : '-'
      }
    end

    pdf.move_pointer 12

    unless column_data.blank?
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = column_data
        table.column_order = column_order.map(&:first)
        table.split_rows = true
        table.font_size = 8
        table.shade_color = Color::RGB::Grey90
        table.shade_heading_color = Color::RGB::Grey70
        table.heading_font_size = 10
        table.shade_headings = true
        table.position = :left
        table.orientation = :right
        table.render_on pdf
      end
    end

    unless @columns.blank? || @query.blank?
      pdf.move_pointer 12
      columns = @columns.map {|c| "<b>#{User.human_attribute_name(c)}</b>"}

      pdf.text t(:'user.pdf.filtered_by',
        :query => @query.map {|q| "<b>#{q}</b>"}.join(', '),
        :columns => columns.to_sentence, :count => @columns.size),
        :font_size => 8
    end

    pdf_name = t :'user.pdf.pdf_name'

    pdf.custom_save_as(pdf_name, User.table_name)

    redirect_to PDF::Writer.relative_path(pdf_name, User.table_name)
  end

  # * POST /users/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:user_data][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = ["#{Organization.table_name}.id = :organization_id"]
    parameters = {:organization_id => @auth_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.function) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.user) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters["user_data_#{i}".to_sym] = "%#{t.downcase}%"
    end
    find_options = {
      :include => :organizations,
      :conditions => [conditions.map {|c| "(#{c})"}.join(' AND '), parameters],
      :order => [
        "#{User.table_name}.last_name ASC", "#{User.table_name}.name ASC"
      ].join(','),
      :limit => 10
    }

    @users = User.all(find_options)
  end

  private

  # Busca el usuario indicado siempre que pertenezca a la organización. En el
  # caso que no se encuentre (ya sea que no existe un usuario con ese ID o que
  # no pertenece a la organización con la que se autenticó el usuario) devuelve
  # nil.
  # _id_::  ID (campo usuario) del usuario que se quiere recuperar
  def find_with_organization(id, field = 'user') #:doc:
    User.first(
      :include => :organizations,
      :conditions => [
        [
          "#{User.table_name}.#{field} = :id",
          [
            "#{Organization.table_name}.id = :organization_id",
            "#{Organization.table_name}.id IS NULL"
          ].join(' OR ')
        ].map {|c| "(#{c})"}.join(' AND '),
        {:id => id, :organization_id => @auth_organization.id}
      ],
      :readonly => false
    )
  end

  def load_privileges #:nodoc:
    if @action_privileges
      @action_privileges.update({
        :auto_complete_for_user => :read,
        :roles => :read,
        :export_to_pdf => :read,
        :blank_password => :modify,
        :user_reassignment => :modify,
        :user_release => :modify
      })
    end
  end
end