class ResourceClassesController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_resource_class, only: [:show, :edit, :update, :destroy]
  before_action :set_title

  # * GET /resource_classes
  def index
    @resource_classes = ResourceClass.list.order(name: :asc).page(params[:page])
  end

  # * GET /resource_classes/1
  def show
  end

  # * GET /resource_classes/new
  def new
    @resource_class = ResourceClass.new
  end

  # * GET /resource_classes/1/edit
  def edit
  end

  # * POST /resource_classes
  def create
    @resource_class = ResourceClass.list.new resource_class_params

    @resource_class.save
    respond_with @resource_class
  end

  # * PATCH /resource_classes/1
  def update
    update_resource @resource_class, resource_class_params
    respond_with @resource_class, location: resource_classes_url unless response_body
  end

  # * DELETE /resource_classes/1
  def destroy
    @resource_class.destroy
    respond_with @resource_class
  end

  private

    def set_resource_class
      @resource_class = ResourceClass.list.find params[:id]
    end

    def resource_class_params
      params.require(:resource_class).permit(
        :name, :resource_class_type, :lock_version,
        resources_attributes: [
          :id, :name, :description, :_destroy
        ]
      )
    end
end
