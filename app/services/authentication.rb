class Authentication
  attr_reader :message, :redirect_url

  def initialize params, request, session, current_organization, admin_mode
    @current_organization, @admin_mode = current_organization, admin_mode
    @params, @request, @session = params, request, session

    set_resources
  end

  def user
    @valid_user
  end

  def authenticated?
    authenticate

    if @valid && @valid_user
      if @current_organization.try(:ldap_config)
        verify_pending_poll
      elsif @current_organization&.saml_provider.present?
        verify_pending_poll
      else
        verify_days_for_password_expiration
        verify_pending_poll
        verify_if_must_change_the_password
      end
    else
      @message ||= I18n.t 'message.invalid_user_or_password'
      @redirect_url ||= { controller: 'sessions', action: 'new' }

      register_login_error
    end

    @valid && @valid_user
  end

  private

    def set_resources
      set_saml_user
      set_login_user
      set_ldap_config
      set_valid_user
    end

    def set_saml_user
      if @current_organization&.saml_provider.present?
        provider      = @current_organization.saml_provider
        saml_config   = IdpSettingsAdapter.saml_settings provider
        saml_response = OneLogin::RubySaml::Response.new @params[:SAMLResponse], settings: saml_config

        if saml_response.is_valid?
          @user = saml_user_for saml_response.nameid, saml_response.attributes
        end
      end
    end

    def saml_user_for email, attributes
      pruned_attributes = send("prune_#{@current_organization.saml_provider}_attributes", attributes)
      email             = pruned_attributes[:email] || email
      @params[:user]    = pruned_attributes[:user]

      if user = User.find_by(user: @params[:user])
        update_user user, pruned_attributes.merge(email: email)
      else
        create_user pruned_attributes.merge(email: email)
      end
    end

    def update_user user, attributes
      current_roles = user.organization_roles.where organization_id: @current_organization.id
      remove_roles  = current_roles.includes(:role).references(:roles).where.not roles: { name: attributes[:roles] }
      add_roles     = Array(attributes[:roles]).select do |name|
        current_roles.includes(:role).references(:roles).where(roles: { name: name }).empty?
      end

      User.transaction do
        user.organization_roles.where(id: remove_roles.ids).destroy_all

        add_roles.each do |name|
          role = Role.where(organization_id: @current_organization.id, name: name).take

          if role
            user.organization_roles.create! organization_id: role.organization_id,
                                            role_id:         role.id
          end
        end

        user.update! user:      attributes[:user],
                     email:     attributes[:email],
                     name:      attributes[:name],
                     last_name: attributes[:last_name],
                     enable:    true
      end

      user if user.organization_roles.where(organization_id: @current_organization.id).any?
    end

    def create_user attributes
      roles = Role.where organization_id: @current_organization.id, name: attributes[:roles]

      if roles.any?
        User.create!(
          name:                          attributes[:name],
          last_name:                     attributes[:last_name],
          email:                         attributes[:email],
          user:                          attributes[:user],
          enable:                        true,
          organization_roles_attributes: roles.map do |r|
            { organization_id: r.organization_id, role_id: r.id }
          end
        )
      end
    end

    def prune_azure_attributes attributes
      {
        user:      Array(attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']).first.to_s.sub(/@.+/, ''),
        name:      Array(attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname']).first,
        email:     Array(attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']).first,
        last_name: Array(attributes['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']).first,
        roles:     attributes['http://schemas.microsoft.com/ws/2008/06/identity/claims/groups']
      }
    end

    def unmasked_user
      user = @params[:user]

      @ldap_config ? @ldap_config.unmasked_user(user) : user
    end

    def set_login_user
      @user ||= User.new user: @params[:user], password: @params[:password]
    end

    def set_ldap_config
      @ldap_config = @current_organization && choose_ldap_config(@params[:user])
    end

    def set_valid_user
      conditions = ["LOWER(#{User.quoted_table_name}.#{User.qcn('user')}) = :user"]
      parameters = { user: unmasked_user.to_s.downcase.strip }

      if @admin_mode
        conditions << "#{User.quoted_table_name}.#{User.qcn('group_admin')} = :true"
        parameters[:true] = true
      else
        conditions << "#{Organization.quoted_table_name}.#{Organization.qcn('id')} = :organization_id"
        parameters[:organization_id] = @current_organization.id
      end

      @valid_user = User.includes(:organizations).where(conditions.join(' AND '), parameters).
        references(:organizations).first
    end

    def encrypt_password
      @user.salt = @valid_user.salt
      @user.encrypt_password
    end

    def concurrent_access_message
      unless @valid_user.allow_concurrent_access?
        @message = I18n.t 'message.you_are_already_logged'
      end
    end

    def authenticate
      if @current_organization.try(:ldap_config)
        ldap_auth
      elsif @current_organization&.saml_provider.present?
        saml_auth
      else
        local_auth
      end
    end

    def saml_auth
      if @user&.valid?
        @valid        = true
        @valid_user   = @user
        @redirect_url = @session[:go_to] || { controller: 'welcome', action: 'index' }

        register_login
      else
        @redirect_url = { controller: 'sessions', action: 'new', saml_error: true }
      end
    end

    def ldap_auth
      ldap = @ldap_config.ldap @user.user, @user.password

      @valid = @user.password.present? && ldap.bind

      if @valid && @valid_user
        register_login

        @redirect_url = @session[:go_to] || { controller: 'welcome', action: 'index' }
      end
    rescue Net::LDAP::Error, Errno::ECONNRESET, Errno::ECONNREFUSED => ex
      ::Rails.logger.error ex

      if @ldap_config.try_alternative_ldap?
        @ldap_config = @ldap_config.alternative_ldap

        retry
      end

      @message = I18n.t('message.ldap_error')
    end

    def choose_ldap_config username
      ldap_configs = @current_organization.group.ldap_configs
      ldap_config  = ldap_configs.detect do |config|
        username =~ config.mask_regex
      end

      ldap_config || @current_organization.ldap_config
    end

    def local_auth
      if @valid_user && !concurrent_access_message
        encrypt_password

        if @admin_mode
          authenticate_admin_mode
        else
          authenticate_normal_mode
        end
      end
    end

    def authenticate_admin_mode
      if @valid_user.is_group_admin? && valid_password?
        register_login
        @redirect_url = Group
        @valid = true
      end
    end

    def authenticate_normal_mode
      verify_if_user_expired

      if @valid_user.is_enable? && !@valid_user.hidden && valid_password?
        register_login
        @valid = true
        @redirect_url = @session[:go_to] || { controller: 'welcome', action: 'index' }
      end
    end

    def valid_password?
      @user.password == @valid_user.password && @user.password_was_encrypted
    end

    def register_login_error
      user = User.find_by user: @user.user

      if user && @current_organization && @current_organization.ldap_config.blank?
        create_error_record user: user, error_type: :on_login
        user.failed_attempts += 1

        if max_attempts_exceeded(user)
          user.enable = false
          create_error_record user: user, error_type: :user_disabled
        end

        user.is_an_important_change = false
        user.save(validate: false)
      elsif @current_organization
        create_error_record user_name: @user.user, error_type: :on_login
      end
    end

    def max_attempts_exceeded user
      max_attempts = @admin_mode ? 3 : user.get_parameter(:attempts_count).to_i

      max_attempts != 0 && user.failed_attempts >= max_attempts && user.is_enable?
    end

    def create_error_record parameters
      ErrorRecord.list.create! parameters.merge(request: @request)
    end

    def verify_if_must_change_the_password
      if @valid_user.must_change_the_password?
        @message = I18n.t 'message.must_change_the_password'
        @redirect_url = [:edit, :users_password, id: @valid_user]
      end
    end

    def verify_if_user_expired
      if @valid_user.expired?
        @valid_user.is_an_important_change = false
        @valid_user.update(enable: false)
      end
    end

    def verify_days_for_password_expiration
      days_for_password_expiration = @valid_user.days_for_password_expiration

      @message = I18n.t(
        days_for_password_expiration >= 0 ? 'message.password_expire_in_x' :
          'message.password_expired_x_days_ago',
          count: days_for_password_expiration.abs
      ) if days_for_password_expiration
    end

    def verify_pending_poll
      if poll = @valid_user.first_pending_poll
        @message = I18n.t(
          'polls.has_unanswered',
          count: @valid_user.list_unanswered_polls.count
        )

        @redirect_url = [:edit, poll, token: poll.access_token]
      end
    end

    def register_login
      if @current_organization
        login_record = LoginRecord.list.create!(user: @valid_user, request: @request)
        @session[:record_id] = login_record.id
      end
    end
end
