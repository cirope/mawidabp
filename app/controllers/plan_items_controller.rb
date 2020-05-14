class PlanItemsController < ApplicationController
  include AutoCompleteFor::ControlObjective

  respond_to :js

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_plan
  before_action :set_plan_item, only: [:show, :edit, :update]

  def show
  end

  def new
    @plan_item = @plan.plan_items.new
  end

  def edit
  end

  def update
    update_resource @plan_item, plan_item_params
  end

  private

    def set_plan
      @plan = Plan.list.find params[:plan_id]
    end

    def set_plan_item
      @plan_item = @plan.plan_items.find params[:id]
    end

    def plan_item_params
      params.require(:plan_item).permit(
        control_objective_projects_attributes: [
          :id, :control_objective_id, :_destroy
        ]
      )
    end

    def load_privileges
      @action_privileges.update auto_complete_for_control_objective: :read
    end
end
