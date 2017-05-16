class Plans::StatsController < ApplicationController
  respond_to :html

  before_action :auth
  before_action :set_title, :set_plan, only: [:show]

  def show
    @until = Timeliness.parse params[:until], :date if params[:until].present?
  end

  private

    def set_plan
      @plan = Plan.list.includes(
        plan_items: { review: :conclusion_final_review }
      ).find params[:id]
    end
end
