class Plans::ActionsController < ApplicationController
  include Plans::Permissions

  respond_to :html

  before_action :auth,
    :check_privileges,
    :check_plan_approval,
    :set_title,
    :set_plan

  def update
    @plan.approved? ? @plan.draft! : @plan.approved!

    redirect_to @plan, notice: t("flash.plans.actions.#{@plan.status}")
  end

  private

    def set_plan
      @plan = Plan.list.find params[:id]
    end
end
