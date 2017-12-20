class ApplicationController < ActionController::Base
  include ActionTitle
  include UpdateResource
  include ParameterSelector
  include CacheControl

  protect_from_forgery

  before_action :set_paper_trail_whodunnit
  before_action :scope_current_organization

  def current_user
    load_user
    Finding.current_user = @auth_user

    @auth_user.try(:id)
  end

  def current_organization
    @current_organization ||= Organization.by_subdomain(
      request.subdomains.first
    ) if APP_ADMIN_PREFIXES.exclude?(request.subdomains.first)
  end
  helper_method :current_organization

  def can_perform? action
    load_current_module
    allowed_by_type = ALLOWED_MODULES_BY_TYPE[@auth_user.get_type].try(
      :include?, @current_module)
    allowed_by_privileges = @auth_privileges[@current_module] &&
      @auth_privileges[@current_module][@action_privileges[action]]

    allowed_by_type && allowed_by_privileges
  end
  helper_method :can_perform?

  private

    def scope_current_organization
      Group.current_id        = current_organization&.group_id
      Group.corporate_ids     = current_organization&.group&.organizations&.corporate&.ids
      Organization.current_id = current_organization&.id
    end

    def load_user
      if @auth_user.nil? && session[:user_id]
        @auth_user = User.includes(
          organization_roles: { role: :privileges }
        ).find(session[:user_id])
      end
    end

    def login_check
      current_organization
      load_user

      !@auth_user.nil? && (@auth_user.is_group_admin? || @auth_user.is_enable?)
    end

    def auth
      action = (params[:action] || 'none').to_sym

      if login_check
        check_access_time

        session[:back_to] = nil if action == :index

        if current_organization.try(:ldap_config).blank? &&
            @auth_user.try(:must_change_the_password?) &&
            ![:edit_password, :update_password].include?(action)
          flash.notice ||= t 'message.must_change_the_password'
          redirect_to edit_users_password_url(@auth_user)
        end

        @action_privileges = ActiveSupport::HashWithIndifferentAccess.new(:approval).update(
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
        store_go_to = request.get? && !request.xhr?
        session[:go_to] = go_to if store_go_to
        @auth_user = nil
        redirect_to_login t('message.must_be_authenticated'), :alert
      end
    end

    # Verifica el último acceso del usuario para comprobar si la sesión ha
    # expirado. Puede deshabilitarse con el parámetro
    # :_session_expire_time_
    def check_access_time #:doc:
      last_access    = session[:last_access] || 10.years.ago
      session_expire = current_organization ?
        parameter_in(current_organization.id, :session_expire_time).to_i : 30

      if session_expire == 0 || last_access >= session_expire.minutes.ago
        session[:last_access] = Time.zone.now

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
      flash_temp = flash.to_hash
      reset_session if session.present?
      flash.replace flash_temp
    end

    def module_name_for(controller_name)
      if current_organization
        modules = @auth_user.audited? ? APP_AUDITED_MENU_ITEMS : APP_AUDITOR_MENU_ITEMS
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
      controller_name = controller_path.split('/').first
      @current_module ||= module_name_for(controller_name.to_sym).try(:menu_name)
    end

    # Comprueba que se tengan privilegios para la acción en curso, en caso de no
    # tenerlos se produce una redirección a la página de ingreso (ver
    # #redirect_to_login)
    def check_privileges #:doc:
      current_action = action_name.to_sym

      unless can_perform?(current_action)
        if request.xhr?
          render :partial => 'shared/ajax_message', :layout => false,
            :locals => {:message => t('message.insufficient_privileges')}
        else
          redirect_back fallback_location: login_url, alert: t('message.insufficient_privileges')
        end
      end

    rescue ActionController::RedirectBackError
      restart_session
      redirect_to_login t('message.insufficient_privileges'), :alert
    end

    def check_group_admin
      unless @auth_user.is_group_admin?
        redirect_back fallback_location: login_url, alert: t('message.insufficient_privileges')
      end

    rescue ActionController::RedirectBackError
      restart_session
      redirect_to_login t('message.insufficient_privileges'), :alert
    end

    def make_date_range(parameters = nil)
      if parameters
        from_date = Timeliness.parse(parameters[:from_date], :date)
        to_date = Timeliness.parse(parameters[:to_date], :date)
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
      if params[:search] && params[:search][:order].present?
        @order_by = model.columns_for_sort[params[:search][:order]][:field]
        @order_by_column_name = model.columns_for_sort[params[:search][:order]][:name]
      end

      if params[:search] && params[:search][:query].present?
        raw_query = params[:search][:query].to_s.mb_chars.downcase.to_s
        and_query = raw_query.split(SEARCH_AND_REGEXP).reject(&:blank?)
        @query = and_query.map do |query|
          query.split(SEARCH_OR_REGEXP).reject(&:blank?)
        end
        @columns = params[:search][:columns] || []
        search_string = []
        filters = { :boolean_false => false }


        @query.each_with_index do |or_queries, i|
          or_search_string = []

          or_queries.each_with_index do |or_query, j|
            @columns.each do |column|
              clean_or_query, operator = *extract_operator(or_query)

              if clean_or_query =~ model.get_column_regexp(column) && (!operator || model.allow_search_operator?(operator, column))
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

                filters[:"#{column}_filter_#{index}"] = model.get_column_mask(column) % casted_value
              end
            end
          end

          if or_search_string.present?
            search_string << "(#{or_search_string.join(' OR ')})"
          end
        end

        @conditions = @columns.empty? || search_string.empty? ?
          default_conditions :
          model.prepare_search_conditions(default_conditions, [search_string.join(' AND '), filters])
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
