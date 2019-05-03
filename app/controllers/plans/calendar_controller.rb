class Plans::CalendarController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_title, :set_plan

  def show
  end

  private

    def set_plan
      @plan = Plan.list.find params[:id]
    end
end
