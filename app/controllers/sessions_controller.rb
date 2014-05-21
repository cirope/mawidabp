class SessionsController < ApplicationController
  before_action :auth, only: [:destroy]
  before_action :set_group_admin_mode, :set_valid_user, only: [:create]

  def new
    redirect_to welcome_url if @auth_user

    @title = t 'user.login_title'
  end

  def create
    @title = t 'user.login_title'
    @user = User.new user: params[:user], password: params[:password]

    if current_organization || @group_admin
      if @valid_user
        @user.salt = @valid_user.salt
        @user.encrypt_password

        if !@group_admin && auth_user.must_change_the_password?
          session[:user_id] = auth_user.id
          flash.notice ||= t 'message.must_change_the_password'
          session[:go_to] = edit_password_user_url(auth_user)
        elsif !@group_admin_mode && auth_user.expired?
          auth_user.is_an_important_change = false
          auth_user.update(enable: false)
        end

        if !@group_admin_mode && auth_user.is_enable? && !auth_user.hidden &&
            @user.password_was_encrypted && auth_user.password == @user.password
          record = LoginRecord.list.new(user: auth_user, request: request)

          if record.save
            days_for_password_expiration = auth_user.days_for_password_expiration

            if days_for_password_expiration
              flash.notice = t(days_for_password_expiration >= 0 ?
                  'message.password_expire_in_x' :
                  'message.password_expired_x_days_ago',
                count: days_for_password_expiration.abs)
            end

            unless auth_user.allow_concurrent_access?
              auth_user = nil
              @user = User.new
              flash.alert = t 'message.you_are_already_logged'

              render action: :new
            end

            session[:last_access] = Time.now
            auth_user.logged_in!(session[:last_access])
            session[:user_id] = auth_user.id
            if poll = auth_user.first_pending_poll
              flash.notice = t 'poll.must_answer_poll'
              go_to = edit_poll_url(poll, token: poll.access_token, layout: 'clean')
            else
              go_to = session[:go_to] || welcome_url
            end
            session[:go_to], session[:record_id] = nil, record.id

            redirect_to go_to
          end
        elsif @group_admin_mode && auth_user.is_group_admin? &&
            auth_user.password == @user.password
          session[:last_access] = Time.now
          auth_user.logged_in!(session[:last_access])
          session[:user_id] = auth_user.id

          redirect_to groups_url
        end
      else
        if (user = User.find_by(user: @user.user))
          ErrorRecord.list.create(
            user: user, request: request, error_type: :on_login
          )

          user.failed_attempts += 1
          max_attempts = @group_admin_mode ?
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
    else
      flash.alert = t 'message.no_organization'
      render action: :new unless session[:user_id]
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
    def valid_user
      conditions = ["LOWER(#{User.table_name}.user) = :user"]
      parameters = { user: params[:user].to_s.downcase.strip }

      if group_admin_mode
        conditions << "#{User.table_name}.group_admin = :true"
        parameters[:true] = true
      else
        conditions << "#{Organization.table_name}.id = :organization_id"
        parameters[:organization_id] = current_organization.id
      end

      @valid_user = User.includes(:organizations).where(conditions.join(' AND '), parameters).
        references(:organizations).first
    end

    def set_group_admin_mode
      @group_admin = APP_ADMIN_PREFIXES.include?(request.subdomains.first)
    end
end
