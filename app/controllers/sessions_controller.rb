class SessionsController < ApplicationController
  before_action :auth, only: [:destroy]
  before_action :set_group_admin, :verify_organization, :set_login_user, only: [:create]

  def new
    auth_user = User.find(session[:user_id]) if session[:user_id]

    if auth_user.try(:is_enable?) && auth_user.logged_in?
      redirect_to welcome_url
    else
      @title = t 'user.login_title'
    end
  end

  def create
    @title = t 'user.login_title'

    if set_valid_user
      encrypt_password

      if !@group_admin
        verify_if_must_change_the_password
        verify_if_user_expired
        autheticate_user
      elsif @group_admin && @valid_user.is_group_admin? && @valid_user.password == @user.password
        @go_to = groups_url
      end

      session[:last_access] = Time.now
      @valid_user.logged_in!(session[:last_access])
      session[:user_id] = @valid_user.id

      redirect_to @go_to
    else
      if (user = User.find_by(user: @user.user))
        ErrorRecord.list.create(
          user: user, request: request, error_type: :on_login
        )

        user.failed_attempts += 1
        max_attempts = @group_admin ?
          3 : user.get_parameter(:attempts_count).to_i

        if (max_attempts != 0 && user.failed_attempts >= max_attempts) &&
            user.is_enable?
          user.enable = false

          ErrorRecord.list.create(
            user: user, request: request, error_type: :user_disabled
          )
        end

        user.is_an_important_change = false
        user.save(validate: false)
      else
        ErrorRecord.list.create(
          user_name: @user.user, request: request, error_type: :on_login
        )
      end

      @user.password = nil
      flash.alert = t 'message.invalid_user_or_password'
      render action: :new
    end
  end

  def destroy
    if session[:record_id] && LoginRecord.exists?(session[:record_id])
      LoginRecord.find(session[:record_id]).end!
    end

    @auth_user.logout! if @auth_user

    restart_session
    redirect_to_login t('message.session_closed_correctly')
  end

  private
    def set_group_admin
      @group_admin = APP_ADMIN_PREFIXES.include?(request.subdomains.first)
    end

    def set_login_user
      @user = User.new user: params[:user], password: params[:password]
    end

    def set_valid_user
      conditions = ["LOWER(#{User.table_name}.user) = :user"]
      parameters = { user: params[:user].to_s.downcase.strip }

      if @group_admin
        conditions << "#{User.table_name}.group_admin = :true"
        parameters[:true] = true
      else
        conditions << "#{Organization.table_name}.id = :organization_id"
        parameters[:organization_id] = current_organization.id
      end

      @valid_user = User.includes(:organizations).where(conditions.join(' AND '), parameters).
        references(:organizations).first
    end

    def verify_organization
      unless (current_organization || @group_admin)
        flash.alert = t 'message.no_organization'
        render action: :new unless session[:user_id]
      end
    end

    def encrypt_password
      @user.salt = @valid_user.salt
      @user.encrypt_password
    end

    def verify_if_must_change_the_password
      if @valid_user.must_change_the_password?
        flash.notice ||= t 'message.must_change_the_password'
        session[:go_to] = edit_password_user_url(@valid_user)
      end
    end

    def verify_if_user_expired
      if @valid_user.expired?
        @valid_user.is_an_important_change = false
        @valid_user.update(enable: false)
      end
    end

    def autheticate_user
      if @valid_user.is_enable? && !@valid_user.hidden &&
        @valid_user.password == @user.password

        if register_login
          @go_to = welcome_url
          verify_days_for_password_expiration
          verify_concurrent_access
          verify_pending_poll
        end
      end
    end

    def verify_pending_poll
      if poll = @valid_user.first_pending_poll
        flash.notice = t 'poll.must_answer_poll'
        @go_to = edit_poll_url(poll, token: poll.access_token, layout: 'clean')
      end
    end

    def verify_concurrent_access
      unless @valid_user.allow_concurrent_access?
        @valid_user = nil
        flash.alert = t 'message.you_are_already_logged'
        @go_to = login_url
      end
    end

    def verify_days_for_password_expiration
      days_for_password_expiration = @valid_user.days_for_password_expiration

      if days_for_password_expiration
        flash.notice = t(
          days_for_password_expiration >= 0 ?
            'message.password_expire_in_x' :
            'message.password_expired_x_days_ago',
            count: days_for_password_expiration.abs
        )
      end
    end

    def register_login
      LoginRecord.list.create(user: @valid_user, request: request)
    end
end
