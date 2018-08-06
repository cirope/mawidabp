module Users::Searches
  extend ActiveSupport::Concern

  included do
    before_action :auth, :check_privileges, :set_users
  end

  private

    def set_users
      conditions = build_search_conditions User

      @users = User.list_with_corporate.not_hidden.where(conditions).limit(10)
    end
end
