class ProcessControlsController < ApplicationController
  respond_to :js

  before_action :auth
  before_action :set_best_practice
  before_action :set_process_control, only: [:edit]

  def new
    @process_control = @best_practice.process_controls.new
  end

  def edit
  end

  private

    def set_best_practice
      @best_practice = BestPractice.list.find params[:best_practice_id]
    end

    def set_process_control
      @process_control = @best_practice.process_controls.find params[:id]
    end
end
