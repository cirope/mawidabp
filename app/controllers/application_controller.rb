# =Controlador de la aplicación
#
# Controlador del que heredan los demás controladores de la aplicación.
#
# Todas las funciones definidas aquí están disponibles para *TODOS* los demás
# controladores
class ApplicationController < ActionController::Base
  # Funciones para seleccionar la correcta versión de parámetros que debe
  # utilizarse
  include ParameterSelector

  protect_from_forgery

  before_action :scope_current_organization

  # Cualquier excepción no contemplada es capturada por esta función. Se utiliza
  # para mostrar un mensaje de error personalizado
  rescue_from Exception do |exception|
    begin
      error = "#{exception.class}: #{exception.message}\n\n"
      exception.backtrace.each { |l| error << "#{l}\n" }

      logger.error(error)

      @title = t 'error.title'
      create_exception_file exception

      if login_check && response.redirect_url.blank?
        render :template => 'shared/error', :locals => { :error => exception }
      end

      # En caso que la presentación misma de la excepción no salga como se espera
      rescue => ex
        error = "#{ex.class}: #{ex.message}\n\n"
        ex.backtrace.each { |l| error << "#{l}\n" }

        logger.error(error)
    end
  end

  def current_user
    load_user
    Finding.current_user = @auth_user

    @auth_user.try(:id)
  end

  def current_organization
    @current_organization ||= Organization.find_by(
      prefix: request.subdomains.first
    ) unless request.subdomains.first == APP_ADMIN_PREFIX
  end
  helper_method :current_organization

  private
    def scope_current_organization
      Organization.current_id = current_organization.try(:id)
    end

  def load_user
    if @auth_user.nil? && session[:user_id]
      @auth_user = User.includes(
        :organization_roles => {:role => :privileges}
      ).find(session[:user_id])
    end
  end

  # Verifica que el login se haya realizado y el usuario esté activo
  def login_check #:doc:
    current_organization
    load_user

    !@auth_user.nil? && (@auth_user.is_group_admin? || @auth_user.is_enable?) &&
      @auth_user.logged_in?
  end

  # Controla que el usuario esté autenticado y de ser así carga sus permisos.
  # Luego de invocada pone a dispoción las siguientes variables:
  # @*auth_user*::          Contiene la instancia de la clase #User que
  #                         representa al usuario
  # @*current_organization*::  Organización que seleccionó el usuario
  # @*action_privileges*::  Privilegios que tiene el usuario sobre la acción en
  #                         curso
  # @*privileges*::         Contiene los privilegios del usuario sobre cualquier
  #                         parte de la aplicación
  def auth #:doc:
    action = (params[:action] || 'none').to_sym

    if login_check
      case current_organization.try(:kind)
      when 'public'
        I18n.locale = :public_es
      when 'management_control'
        I18n.locale = :mc_es
      else
        I18n.locale = :es
      end
      check_access_time
      response.headers['Cache-Control'] = 'no-cache, no-store'

      session[:back_to] = nil if action == :index

      if @auth_user.try(:must_change_the_password?) &&
           ![:edit_password, :update_password].include?(action)
        flash.notice ||= t 'message.must_change_the_password'
        redirect_to edit_password_user_url(@auth_user)
      end

      @action_privileges = HashWithIndifferentAccess.new(:approval).update(
        :index => :read,
        :show => :read,
        :new => :modify,
        :create => :modify,
        :edit => :modify,
        :update => :modify,
        :destroy => :erase
      )

      @auth_privileges = current_organization ?
        @auth_user.try(:privileges, current_organization) : {}
    else
      go_to = request.fullpath
      session[:go_to] = go_to unless action == :logout || request.xhr?
      @auth_user = nil
      redirect_to_login t('message.must_be_authenticated'), :alert
    end
  end

  # Verifica el último acceso del usuario para comprobar si la sesión ha
  # expirado. Puede deshabilitarse con el parámetro
  # :_session_expire_time_
  def check_access_time #:doc:
    session_expire = current_organization ? parameter_in(current_organization.id,
      :session_expire_time).to_i : 30
    last_access = session[:last_access]

    if session_expire == 0 || last_access >= session_expire.minutes.ago
      session[:last_access] = Time.now

      unless @auth_user.first_login?
        begin
          @auth_user.update(last_access: session[:last_access])
        rescue ActiveRecord::StaleObjectError
          @auth_user.reload
        end
      end
    else
      restart_session
      go_to = request.fullpath if request.get?
      session[:go_to] = params[:action].try(:to_sym) != :logout ? go_to : nil
      @auth_user = nil
      redirect_to_login t('message.session_time_expired'), :alert
    end
  end

  # Redirige la navegación a la página por defecto
  # _message_:: Mensaje que se mostrará luego de la redirección
  def redirect_to_index(message = nil, type = :notice) #:doc:
    flash[type] = message if message
    redirect_to :action => :index
  end

  # Redirige la navegación a la página de autenticación
  # _message_:: Mensaje que se mostrará luego de la redirección
  def redirect_to_login(message = nil, type = :notice) #:doc:
    flash[type] = message if message
    redirect_to login_url
  end

  # Reinicia la sessión (conservando el contenido de flash)
  def restart_session #:doc:
    flash_temp = Marshal::load(Marshal::dump(flash))
    reset_session
    flash.replace flash_temp
  end

  def module_name_for(controller_name)
    if current_organization
      if current_organization.kind == 'quality_management'
        modules =  @auth_user.audited? ? APP_AUDITED_QM_MENU_ITEMS : APP_AUDITOR_QM_MENU_ITEMS
      else
        modules =  @auth_user.audited? ? APP_AUDITED_MENU_ITEMS : APP_AUDITOR_MENU_ITEMS
      end
    end

    top_level_menu = true

    until modules.blank?
      selected_module = nil
      modules.each do |mod|
        if mod.controllers.include?(controller_name) && (top_level_menu ||
          mod.conditions(controller_name).blank? ||
          eval(mod.conditions(controller_name)) ||
          eval(mod.conditions(controller_name, false)))
            selected_module = mod
            top_level_menu = false
        end
      end

      modules = selected_module ? selected_module.children : []
    end

    selected_module
  end

  def load_current_module
    @current_module ||= module_name_for(controller_name.to_sym).try(:menu_name)
  end

  # Comprueba que se tengan privilegios para la acción en curso, en caso de no
  # tenerlos se produce una redirección a la página de ingreso (ver
  # #redirect_to_login)
  def check_privileges #:doc:
    load_current_module
    current_action = action_name.to_sym
    allowed_by_type = ALLOWED_MODULES_BY_TYPE[@auth_user.get_type].try(
      :include?, @current_module)
    allowed_by_privileges = @auth_privileges[@current_module] &&
      @auth_privileges[@current_module][@action_privileges[current_action]]

    unless allowed_by_type && allowed_by_privileges
      unless request.xhr?
        flash.alert = t('message.insufficient_privileges')
        redirect_to :back
      else
        render :partial => 'shared/ajax_message', :layout => false,
          :locals => {:message => t('message.insufficient_privileges')}
      end
    end

  rescue ActionController::RedirectBackError
    restart_session
    redirect_to_login t('message.insufficient_privileges'), :alert
  end

  def check_group_admin
    unless @auth_user.is_group_admin?
      flash.alert = t('message.insufficient_privileges')
      redirect_to :back
    end

  rescue ActionController::RedirectBackError
    restart_session
    redirect_to_login t('message.insufficient_privileges'), :alert
  end

  # Crea un archivo en un directorio propio del usuario a partir de una
  # excepción
  def create_exception_file(exception) #:doc:
    if @auth_user
      dir_name = "#{ERROR_FILES_PATH}#{@auth_user.user}#{File::SEPARATOR}"

      FileUtils.makedirs dir_name

      File.open("#{dir_name}#{t('error.error_file')}.log", 'w') do |out|
        # TODO: cifrar el contenido cuando esté disponible Rails 2.3 con
        # ActiveSupport::MessageEncryptor
        out << "#{exception.class}: #{exception.message}\n\n"

        exception.backtrace.each { |l| out << "#{l}\n" }

        out << "\nENV\n\n"
      end
    end
  end

  def make_date_range(parameters = nil)
    if parameters
      from_date = Timeliness::Parser.parse(parameters[:from_date], :date)
      to_date = Timeliness::Parser.parse(parameters[:to_date], :date)
    end

    from_date ||= Date.today.at_beginning_of_month
    to_date ||= Date.today.at_end_of_month

    [from_date.to_date, to_date.to_date].sort
  end

  def extract_operator(search_term)
    operator = SEARCH_ALLOWED_OPERATORS.detect do |op_regex, _|
      search_term =~ op_regex
    end

    operator ? [search_term.sub(operator.first, ''), operator.last] : search_term
  end

  def build_search_conditions(model, default_conditions = {})
    if params[:search] && !params[:search][:order].blank?
      @order_by = model.columns_for_sort[params[:search][:order]][:field]
      @order_by_column_name =
        model.columns_for_sort[params[:search][:order]][:name]
    end

    if params[:search] && !params[:search][:query].blank?
      raw_query = Unicode::downcase(params[:search][:query] || '')
      and_query = raw_query.split(SEARCH_AND_REGEXP).reject { |q| q.blank? }
      @query = and_query.map do |query|
        query.split(SEARCH_OR_REGEXP).reject { |q| q.blank? }
      end
      @columns = params[:search][:columns] || []
      search_string = []
      filters = {:boolean_false => false}


      @query.each_with_index do |or_queries, i|
        or_search_string = []

        or_queries.each_with_index do |or_query, j|
          @columns.each do |column|
            clean_or_query, operator = *extract_operator(or_query)

            if clean_or_query =~ model.get_column_regexp(column) &&
                (!operator || model.allow_search_operator?(operator, column))
              index = i * 1000 + j
              conversion_method = model.get_column_conversion_method(column)
              filter = "#{model.get_column_name(column)} "
              operator ||= model.get_column_operator(column).kind_of?(Array) ?
                '=' : model.get_column_operator(column)

              filter << operator
              or_search_string << "#{filter} :#{column}_filter_#{index}"

              if conversion_method.respond_to?(:call)
                casted_value = conversion_method.call(clean_or_query.strip)
              else
                casted_value = clean_or_query.strip.send(conversion_method) rescue nil
              end

              filters["#{column}_filter_#{index}".to_sym] =
                model.get_column_mask(column) % casted_value
            else
              or_search_string << ':boolean_false'
            end
          end
        end

        unless or_search_string.blank?
          search_string << "(#{or_search_string.join(' OR ')})"
        end
      end

      @conditions = @columns.empty? || search_string.empty? ?
        default_conditions :
        model.prepare_search_conditions(default_conditions,
          [search_string.join(' AND '), filters])
    else
      @columns = []
      @conditions = default_conditions
    end
  end

  def help
    Helper.instance
  end

  class Helper
    include Singleton
    include ApplicationHelper
  end
end
