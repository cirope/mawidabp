class Plans::ResourcesController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_title, :set_plan

  def show
    respond_to do |format|
      format.html
      format.pdf  { redirect_to pdf.relative_path }
    end
  end

  private

    def set_plan
      @plan = Plan.list.find params[:id]
      @human_resource_utilizations = @plan.
        resource_utilizations.
        joins(:user, :plan_item).
        includes(:user, :plan_item).
        group_by(&:resource_id)
    end

    def pdf
      PlanResourcesPdf.create(
        title: t('.title'),
        plan: @plan,
        human_resource_utilizations: @human_resource_utilizations,
        current_organization: current_organization
      )
    end
end
