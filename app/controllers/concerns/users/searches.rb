module Users::Searches
  extend ActiveSupport::Concern

  included do
    before_action :auth, :check_privileges, :set_users
  end

  private

    def set_users
      conditions = complex_search(
        model: User,
        raw_query: params[:q],
        columns: ::User::COLUMNS_FOR_SEARCH.keys
      )[:conditions]

      @users = User.list_with_corporate.not_hidden.where(conditions).limit(10)
    end
end
