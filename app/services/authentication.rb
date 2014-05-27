class Authentication
  attr_reader :message, :redirect_url

  def initialize params, request, current_organization, admin_mode
    @current_organization = current_organization
    @params, @request, @admin_mode = params, request, admin_mode

    set_resources
  end

  def user
    @valid_user
  end

  def authenticated?
    authenticate

    if @valid
      verify_days_for_password_expiration
      verify_pending_poll
      verify_if_user_expired
      verify_if_must_change_the_password
      @message ||= 'message.welcome'
    else
      @message ||= 'message.invalid_user_or_password'
      @redirect_url = Array 'login'
      register_login_error
    end

    @valid
  end

  private

    def set_resources
      set_login_user
      set_valid_user
    end

    def set_login_user
      @user = User.new user: @params[:user], password: @params[:password]
    end

    def set_valid_user
      conditions = ["LOWER(#{User.table_name}.user) = :user"]
      parameters = { user: @params[:user].to_s.downcase.strip }

      if @admin_mode
        conditions << "#{User.table_name}.group_admin = :true"
        parameters[:true] = true
      else
        conditions << "#{Organization.table_name}.id = :organization_id"
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
        @message = 'message.you_are_already_logged'
      end
    end

    def authenticate
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
      if @valid_user.is_group_admin? && @valid_user.password == @user.password
        @redirect_url = Array 'groups'
        @valid = true
      end
    end

    def authenticate_normal_mode
      if @valid_user.is_enable? && !@valid_user.hidden &&
        @valid_user.password == @user.password

        if register_login
          @redirect_url = Array 'welcome'
          @valid = true
        end
      end
    end

    def register_login_error
      user = User.find_by user: @user.user

      if user
        create_error_record user: user, error_type: :on_login

        if max_attempts_exceeded(user)
          user.enable = false
          create_error_record user: user, error_type: :user_disabled
        end

        user.failed_attempts += 1
        user.is_an_important_change = false
        user.save(validate: false)
      else
        create_error_record user_name: @user.user, error_type: :on_login
      end
    end

    def max_attempts_exceeded user
      max_attempts = @admin_mode ? 3 : user.get_parameter(:attempts_count).to_i

      max_attempts != 0 && user.failed_attempts >= max_attempts && user.is_enable?
    end

    def create_error_record parameters
      ErrorRecord.list.create parameters.merge(request: @request)
    end

    def verify_if_must_change_the_password
      if @valid_user.must_change_the_password?
        @message = 'message.must_change_the_password'
        @redirect_url = ['edit', 'password', @valid_user]
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

      @message = [
        days_for_password_expiration >= 0 ? 'message.password_expire_in_x' :
          'message.password_expired_x_days_ago',
          count: days_for_password_expiration.abs
      ] if days_for_password_expiration
    end

    def verify_pending_poll
      if poll = @valid_user.first_pending_poll
        @message = 'poll.must_answer_poll'
        @redirect_url = ['edit', poll, token: poll.access_token, layout: 'clean']
      end
    end


    def register_login
      LoginRecord.list.create(user: @valid_user, request: @request)
    end
end
