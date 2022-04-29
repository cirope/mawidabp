class ApplicationController < ActionController::Base
  include ActionTitle
  include UpdateResource
  include ParameterSelector
  include CacheControl
  include FlashResponders
  include LicenseCheck if ENABLE_PUBLIC_REGISTRATION

  protect_from_forgery

  before_action :set_paper_trail_whodunnit
  before_action :scope_current_organization
  before_action :set_conclusion_pdf_format

  def current_user
    load_user
    Current.user = @auth_user

    @auth_user.try(:id)
  end

  def current_organization
    @current_organization ||= Organization.by_subdomain(
      request.subdomains.first
    ) if request.subdomains.any? && APP_ADMIN_PREFIXES.exclude?(request.subdomains.first)
  end
  helper_method :current_organization

  def can_perform? action, privilege = nil
    load_current_module

    privilege ||= @action_privileges[action]

    allowed_by_type = ALLOWED_MODULES_BY_TYPE[@auth_user.get_type].try(
      :include?, @current_module)

    allowed_by_privileges = @auth_privileges[@current_module] &&
      @auth_privileges[@current_module][privilege]

    select_module_in_children privilege if @drop_down_menu

    allowed_by_type && allowed_by_privileges && @current_module
  end
  helper_method :can_perform?

  def select_module_in_children privilege
    @current_module = nil

    @current_menu_item.children.each do |children_menu_item|
      allowed_by_type = ALLOWED_MODULES_BY_TYPE[@auth_user.get_type].try(
        :include?, children_menu_item.menu_name)

      allowed_by_privileges = @auth_privileges[children_menu_item.menu_name] &&
        @auth_privileges[children_menu_item.menu_name][privilege]

      if @current_module.blank? && allowed_by_type && allowed_by_privileges
        @current_module    = children_menu_item.try(:menu_name)
        @current_menu_item = children_menu_item
      end
    end
  end

  def search_params
    @search_params ||= params[:search]&.permit(:query, columns: []).to_h.symbolize_keys
  end
  helper_method :search_params

  def order_param
    @order_param ||= params[:search]&.permit(:order)&.fetch :order, nil
  end
  helper_method :order_param

  private

    def scope_current_organization
      Current.group         = current_organization&.group
      Current.corporate_ids = current_organization&.group&.organizations&.corporate&.ids
      Current.organization  = current_organization
    end

    def set_conclusion_pdf_format
      prefix = current_organization&.prefix&.downcase

      if SHOW_CONCLUSION_ALTERNATIVE_PDF.respond_to?(:[])
        Current.conclusion_pdf_format = SHOW_CONCLUSION_ALTERNATIVE_PDF[prefix]
      end

      if USE_GLOBAL_WEAKNESS_REVIEW_CODE.include? prefix
        Current.global_weakness_code = true
      end

      Current.conclusion_pdf_format ||= 'default'
    end

    def load_user
      if @auth_user.nil? && session[:user_id]
        @auth_user = User.includes(
          :business_unit_types,
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
            current_organization.try(:saml_provider).blank? &&
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
        store_go_to = request.get? && request.format.html? && !request.xhr?
        session[:go_to] = go_to if store_go_to && go_to !~ /\A\/sessions/
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

    # Redirige la navegación a la página de autenticación
    # _message_:: Mensaje que se mostrará luego de la redirección
    def redirect_to_login(message = nil, type = :notice, params = nil) #:doc:
      flash[type] = message if message
      redirect_to login_url(params)
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

      while modules.present?
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

        if selected_module.blank? || selected_module_is_drop_down_menu?(selected_module)
          modules = []
        else
          modules = selected_module.children
        end
      end

      selected_module
    end

    def selected_module_is_drop_down_menu? selected_module
      selected_module.drop_down_menu && @drop_down_menu
    end

    def load_current_module
      @drop_down_menu = params[:drop_down_menu]
      controller_name = controller_path.split('/').first

      @current_menu_item ||= module_name_for(controller_name.to_sym)
      @current_module    ||= @current_menu_item.try(:menu_name)
    end

    # Comprueba que se tengan privilegios para la acción en curso, en caso de no
    # tenerlos se produce una redirección a la página de ingreso (ver
    # #redirect_to_login)
    def check_privileges #:doc:
      current_action = action_name.to_sym

      if can_perform? current_action
        redirect_to @current_menu_item.url if @drop_down_menu
      elsif request.xhr?
        render :partial => 'shared/ajax_message', :layout => false,
               :locals => {:message => t('message.insufficient_privileges')}
      else
        redirect_back fallback_location: login_url, alert: t('message.insufficient_privileges')
      end
    end

    def check_group_admin
      unless @auth_user.is_group_admin?
        redirect_back fallback_location: login_url, alert: t('message.insufficient_privileges')
      end
    end

    def make_date_range(parameters = nil)
      if parameters
        from_date = Timeliness.parse(parameters[:from_date], :date)
        to_date = Timeliness.parse(parameters[:to_date], :date)
      end

      from_date ||= Time.zone.today.at_beginning_of_month
      to_date ||= Time.zone.today.at_end_of_month

      [from_date.to_date, to_date.to_date].sort
    end

    def extract_cut_date parameters
      cut_date = Timeliness.parse parameters[:cut_date], :date if parameters

      cut_date&.to_date || Time.zone.today
    end

    def extract_operator(search_term)
      operator = SEARCH_ALLOWED_OPERATORS.detect do |op_regex, _|
        search_term =~ op_regex
      end

      operator ? [search_term.sub(operator.first, ''), operator.last] : search_term
    end

    def build_search_conditions(model, default_conditions = {})
      if params[:search] && params[:search][:order].present?
        order_data = model.columns_for_sort[params[:search][:order]]

        @order_by             = order_data[:field]
        @order_by_column_name = order_data[:name]
        @extra_query_values   = order_data[:extra_query_values]
      end

      if params[:search] && params[:search][:query].present?
        @columns = params[:search][:columns] || []

        result = prepare_search(
          model:              model,
          raw_query:          params[:search][:query],
          columns:            @columns,
          default_conditions: default_conditions
        )
        @query      = result[:query]
        @conditions = result[:conditions]
      else
        @columns    = []
        @conditions = default_conditions
      end
    end

    def prepare_search(model:, raw_query: nil, columns: [], default_conditions: {})
      raw_query = raw_query.to_s.mb_chars.downcase.to_s
      and_query = raw_query.split(SEARCH_AND_REGEXP).reject(&:blank?)

      query = and_query.map do |q|
        q.split(SEARCH_OR_REGEXP).reject(&:blank?)
      end

      search_string = []
      filters = { boolean_false: false }

      query.each_with_index do |or_queries, i|
        or_search_string = []

        or_queries.each_with_index do |or_query, j|
          columns.each do |column|
            clean_or_query, operator = *extract_operator(or_query)

            if (
                clean_or_query =~ model.get_column_regexp(column) &&
                (!operator || model.allow_search_operator?(operator, column))
            )
              index = i * 1000 + j
              mask              = model.get_column_mask(column)
              conversion_method = model.get_column_conversion_method(column)
              filter            = "#{model.get_column_name(column)} "
              operator          ||= if model.get_column_operator(column).kind_of?(Array)
                                      '='
                                    else
                                      model.get_column_operator(column)
                                    end

              filter << operator
              or_search_string << "#{filter} :#{column}_filter_#{index}"

              casted_value = if conversion_method.respond_to?(:call)
                               conversion_method.call(clean_or_query.strip)
                             else
                               clean_or_query.strip.send(conversion_method) rescue nil
                             end

              filters[:"#{column}_filter_#{index}"] = mask ? mask % casted_value : casted_value
            end
          end
        end

        search_string << "(#{or_search_string.join(' OR ')})" if or_search_string.present?
      end

      conditions = if columns.empty? || search_string.empty?
                     default_conditions
                   else
                     model.prepare_search_conditions(default_conditions, [search_string.join(' AND '), filters])
                   end

      {
        query: query,
        conditions: conditions
      }
    end

    def help
      Helper.instance
    end

    class Helper
      include Singleton
      include ApplicationHelper
    end
end
