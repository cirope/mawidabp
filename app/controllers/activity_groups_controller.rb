class ActivityGroupsController < ApplicationController
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

    if @activity_group.save
      redirect_with_notice @activity_group
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /activity_groups/1
  def update
    if @activity_group.update activity_group_params
      redirect_with_notice @activity_group
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # DELETE /activity_groups/1
  def destroy
    @activity_group.destroy
    redirect_with_notice @activity_group
  end

  private

    def set_activity_group
      @activity_group = ActivityGroup.group_list.find params[:id]
    end

    def activity_group_params
      params.require(:activity_group).permit :name,
        activities_attributes: [:id, :name, :require_detail, :_destroy]
    end
end
