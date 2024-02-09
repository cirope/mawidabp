class ResourceClassesController < ApplicationController
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

    if @resource_class.save
      redirect_with_notice @resource_class
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # * PATCH /resource_classes/1
  def update
    if @resource_class.update resource_class_params
      redirect_with_notice @resource_class, url: resource_classes_url
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # * DELETE /resource_classes/1
  def destroy
    @resource_class.destroy
    redirect_with_notice @resource_class
  end

  private

    def set_resource_class
      @resource_class = ResourceClass.list.find params[:id]
    end

    def resource_class_params
      params.require(:resource_class).permit(
        :name, :lock_version,
        resources_attributes: [
          :id, :name, :description, :_destroy
        ]
      )
    end
end
