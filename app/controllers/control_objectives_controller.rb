class ControlObjectivesController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_control_objective, only: [:show ]
  before_action :set_title

  # * GET /control_objectives
  def index
    build_search_conditions ControlObjective
    order = if ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced'
              [created_at: :asc]
            else
              [name: :asc]
            end

    @control_objectives = ControlObjective.list.where(@conditions).reorder(
      order
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

