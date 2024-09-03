module Sessions
  extend ActiveSupport::Concern

  included do
    before_action :user_logged_in?, only: [:new]
    before_action :set_admin_mode, :set_organization, :set_current_user, only: [:create]
  end

  private

    def user_logged_in?
      auth_user = User.find(session[:user_id]) if session[:user_id]

      if auth_user&.is_enable? && auth_user&.logged_in?
        redirect_to welcome_url
      end
    end

    def set_admin_mode
      @admin_mode = APP_ADMIN_PREFIXES.include?(request.subdomains.first)
    end

    def set_organization
      unless (current_organization || @admin_mode)
        flash.alert = t 'message.no_organization'
        redirect_to login_url
      end
    end

    def store_user user
      session[:user] = user
    end

    def username
      (params[:user] || session[:user]).to_s.downcase.strip
    end

    def set_current_user
      conditions = [
        [
          "LOWER(#{User.quoted_table_name}.#{User.qcn('user')}) = :user",
          "LOWER(#{User.quoted_table_name}.#{User.qcn('email')}) = :email"
        ].join(' OR ')
      ]

      parameters = { user: username, email: username }

      if @admin_mode
        conditions << "#{User.quoted_table_name}.#{User.qcn('group_admin')} = :true"
        parameters[:true] = true
      else
        conditions << "#{Organization.quoted_table_name}.#{Organization.qcn('id')} = :organization_id"
        parameters[:organization_id] = @current_organization.id
      end

      @current_user = User.includes(:organizations).where(conditions.join(' AND '), parameters).
        references(:organizations).first
    end
end
