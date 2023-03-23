class WorkPapersController < ApplicationController

  before_action :auth, :set_title, :set_work_paper

  def show
  end

  private

    def set_work_paper
      @work_paper = WorkPaper.new description: params[:file_url]
    end
end
