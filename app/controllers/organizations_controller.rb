class OrganizationsController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_organization, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: :destroy

  # * GET /organizations
  def index
    @organizations = Organization.with_group(group).ordered.page(params[:page])
    respond_with @organizations
  end

  # * GET /organizations/1
  def show
    respond_with @organization
  end

  # * GET /organizations/new
  def new
    @organization = Organization.new
    respond_with @organization
  end

  # * GET /organizations/1/edit
  def edit
  end

  # * POST /organizations
  def create
    @organization = Organization.new organization_params

    @organization.save
    respond_with @organization
  end

  # * PATCH /organizations/1
  def update
    update_resource @organization, organization_params
    respond_with @organization, location: organizations_url unless response_body
  end

  # * DELETE /organizations/1
  def destroy
    @organization.destroy
    respond_with @organization
  end

  private

    def group
      current_organization.group
    end

    def group_id
      current_organization.group_id
    end

    def set_organization
      @organization = Organization.find_by group_id: group_id, id: params[:id]
    end

    def organization_params
      params.require(:organization).permit(
        :name, :prefix, :description, :group_id, :image_model_id, :lock_version,
        image_model_attributes: [:id, :image, :image_cache],
        ldap_config_attributes: [
          :id, :hostname, :port, :basedn, :filter, :login_mask,
          :username_attribute, :name_attribute, :last_name_attribute,
          :email_attribute, :function_attribute, :roles_attribute,
          :manager_attribute, :test_user, :test_password
        ]
      )
    end
end
