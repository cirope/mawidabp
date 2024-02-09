class Users::ProfilesController < ApplicationController
  before_action :auth, :set_title

  # * GET /users/profiles/1/edit
  def edit
  end

  # * PATCH /users/profiles/1
  def update
    @auth_user.is_an_important_change = false
    update_resource @auth_user, user_params

    respond_with @auth_user, location: edit_users_profile_url(@auth_user)
  end

  private

    def user_params
      params.require(:user).permit :name, :last_name, :email, :function
    end
end
