class Users::ReassignmentsController < ApplicationController
  include Users::Finders

  respond_to :html

  before_action :auth, :set_user, :set_title

  # * GET /users/reassignment/1/edit
  def edit
  end

  # * PATCH /users/reassignment/1
  def update
    @other = find_with_organization params[:other_id], :id if params[:other_id]

    @user.reassign_to @other,
      with_findings: params[:with_findings] == '1',
      with_reviews:  params[:with_reviews]  == '1'

    respond_with @user, location: users_url
  end
end
