class Users::ProfilesController < ApplicationController
  before_action :auth, :set_title

  # * GET /users/profiles/1/edit
  def edit
  end

  # * PATCH /users/profiles/1
  def update
    @auth_user.is_an_important_change = false

    if @auth_user.update user_params
      redirect_with_notice @auth_user, url: edit_users_profile_url(@auth_user)
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.require(:user).permit :name, :last_name, :email, :function
    end
end
