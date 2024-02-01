class WorkPapersController < ApplicationController

  before_action :auth, :set_title
  before_action :new_work_paper, only: [:show]
  before_action :set_work_paper, only: [:update]

  def show
  end

  def update
    @work_paper.update_status
  end

  private

    def new_work_paper
      @work_paper = WorkPaper.new description: params[:file_url]
    end

    def set_work_paper
      @work_paper = WorkPaper.find params[:id]
    end
end
