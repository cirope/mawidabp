class Plans::ActionsController < ApplicationController
  include PlanAndReviewApproval

  respond_to :html

  before_action :auth, :check_privileges, :set_title, :set_plan
  before_action -> { check_plan_and_review_approval @plan },
    only: [:edit, :update, :destroy]

  def update
    @plan.approved? ? @plan.draft! : @plan.approved!

    redirect_to @plan, notice: t("flash.plans.actions.#{@plan.status}")
  end

  private

    def set_plan
      @plan = Plan.list.find params[:id]
    end
end
