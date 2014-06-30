module Users::Searches
  extend ActiveSupport::Concern

  included do
    before_action :auth, :check_privileges, :set_users

    respond_to :json
  end

  private

    def set_users
      @users = current_organization.users.not_hidden.where.
        not("#{User.table_name}.id = ?", current_user).
        search(params[:q]).limit(10)
    end
end
