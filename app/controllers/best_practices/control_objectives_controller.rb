class BestPractices::ControlObjectivesController < ApplicationController
  respond_to :html

  before_action :auth
  before_action :set_best_practice, :set_control_objective, only: [:download]

  def download
    flash[:allow_path] = @control_objective.support&.path

    redirect_to @control_objective.support&.url || root_url
  end

  private

    def set_best_practice
      @best_practice = BestPractice.list.find params[:best_practice_id]
    end

    def set_control_objective
      @control_objective = @best_practice.control_objectives.find params[:id]
    end
end
