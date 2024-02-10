class Users::ReleasesController < ApplicationController
  include Users::Finders

  before_action :auth, :check_privileges, :set_user, :set_title

  # * GET /users/releases/1/edit
  def edit
  end

  # * PATCH /users/releases/1
  def update
    @user.release_pendings(
      with_findings: params[:with_findings] == '1',
      with_reviews:  params[:with_reviews]  == '1'
    )

    redirect_with_notice @user, url: users_url
  end
end
