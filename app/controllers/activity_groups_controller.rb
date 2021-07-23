class ActivityGroupsController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_activity_group, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET /activity_groups
  def index
    @activity_groups = ActivityGroup.group_list.order(:name).page params[:page]
  end

  # GET /activity_groups/1
  def show
  end

  # GET /activity_groups/new
  def new
    @activity_group = ActivityGroup.list.new
  end

  # GET /activity_groups/1/edit
  def edit
  end

  # POST /activity_groups
  def create
    @activity_group = ActivityGroup.list.new activity_group_params

    @activity_group.save

    respond_with @activity_group
  end

  # PATCH/PUT /activity_groups/1
  def update
    update_resource @activity_group, activity_group_params

    respond_with @activity_group
  end

  # DELETE /activity_groups/1
  def destroy
    @activity_group.destroy

    respond_with @activity_group
  end

  private

    def set_activity_group
      @activity_group = ActivityGroup.list.find params[:id]
    end

    def activity_group_params
      params.require(:activity_group).permit :name,
        activities_attributes: [:id, :name, :require_detail, :_destroy]
    end
end
