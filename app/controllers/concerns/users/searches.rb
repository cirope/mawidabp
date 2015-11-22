module Users::Searches
  extend ActiveSupport::Concern

  included do
    before_action :auth, :check_privileges, :set_users
  end

  private

    def set_users
      @users = User.list.not_hidden.search(params[:q]).limit 10
    end
end
