class Users::RolesController < ApplicationController
  before_action :auth, :check_privileges

  # * GET /users/roles/1
  def index
    organization = Organization.find params[:id]
    @roles = Role.list_by_organization_and_group organization, organization.group
  end
end
