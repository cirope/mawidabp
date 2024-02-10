# frozen_string_literal: true

class ControlObjectivesController < ApplicationController
  include AutoCompleteFor::ControlObjectiveAuditor

  before_action :auth, :check_privileges
  before_action :set_control_objective, only: [:show]
  before_action :set_title

  # * GET /control_objectives
  def index
    @control_objectives = ControlObjective.list.search(
      **search_params
    ).default_order.page params[:page]
  end

  # * GET /control_objectives/1
  def show
  end

  private

    def set_control_objective
      @control_objective = ControlObjective.list.find params[:id]
    end
end

