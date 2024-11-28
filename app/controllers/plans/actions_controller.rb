class Plans::ActionsController < ApplicationController
  respond_to :html

  before_action :auth,
    :check_privileges,
    :check_action,
    :set_title,
    :set_plan

  def update
    @plan.approved? ? @plan.draft! : @plan.approved!

    redirect_to @plan, notice: t("flash.plans.actions.#{@plan.status}")
  end

  private

    def check_action
      unless can_approve_plans_and_reviews?
        redirect_to plans_url, alert: t('messages.not_allowed')
      end
    end

    def set_plan
      @plan = Plan.list.find params[:id]
    end

    def can_approve_plans_and_reviews?
      can_perform?(:edit, :approval) &&
        Current.organization.require_plan_and_review_approval?
    end
end
