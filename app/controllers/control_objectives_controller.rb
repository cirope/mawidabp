class ControlObjectivesController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_control_objective, only: [:show ]
  before_action :set_title

  # * GET /control_objectives
  def index
    build_search_conditions ControlObjective

    @control_objectives = ControlObjective.list.where(@conditions).reorder(
      name: :asc
    ).page(params[:page])
  end

  # * GET /control_objectives/1
  def show
    respond_with @control_objective
  end

  private

    def set_control_objective
      @control_objective = ControlObjective.list.find params[:id]
    end
end

