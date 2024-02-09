class PlanItemsController < ApplicationController
  include AutoCompleteFor::BestPractice
  include AutoCompleteFor::ControlObjective

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_plan
  before_action :set_partial, only: [:show, :update]
  before_action :set_plan_item, only: [:show, :edit, :update]

  def show
  end

  def new
    @plan_item = @plan.plan_items.new
  end

  def edit
  end

  def update
    @plan_item.update plan_item_params
  end

  private

    def set_plan
      @plan = Plan.list.find params[:plan_id]
    end

    def set_plan_item
      @plan_item = @plan.plan_items.find params[:id]
    end

    def set_partial
      @partial = case params[:partial]
                when 'best_practice'
                  'best_practice'
                else
                  'control_objective'
                end
    end

    def plan_item_params
      params.require(:plan_item).permit(
        control_objective_projects_attributes: [
          :id, :control_objective_id, :_destroy
        ],
        best_practice_projects_attributes: [
          :id, :best_practice_id, :_destroy
        ]
      )
    end

    def load_privileges
      @action_privileges.update auto_complete_for_control_objective: :read,
                                auto_complete_for_best_practice: :read
    end
end
