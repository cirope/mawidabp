class PlanItemsController < ApplicationController
  respond_to :js

  before_action :auth
  before_action :set_plan
  before_action :set_plan_item, only: [:edit]

  def new
    @plan_item = @plan.plan_items.new
  end

  def edit
  end

  private

    def set_plan
      @plan = Plan.list.find params[:plan_id]
    end

    def set_plan_item
      @plan_item = @plan.plan_items.find params[:id]
    end
end
