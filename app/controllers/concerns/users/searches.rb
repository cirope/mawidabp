module Users::Searches
  extend ActiveSupport::Concern

  included do
    before_action :auth, :check_privileges, :set_users
  end

  private

    def set_users
      @users = User.includes(:organizations).where(users_conditions).not_hidden.order(
        Arel.sql "#{User.quoted_table_name}.#{User.qcn('user')} ASC"
      ).references(:organizations).page(params[:page])
    end

    def users_conditions
      default_conditions = {
        organization_roles: { organization_id: current_organization.id }
      }

      build_search_conditions User, default_conditions
    end
end
