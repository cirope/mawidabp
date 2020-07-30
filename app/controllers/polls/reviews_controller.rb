class Polls::ReviewsController < ApplicationController
  include Polls::Reports
  include Polls::Filters

  def index
    respond_to do |format|
      format.html
      format.js { create_pdf and render 'shared/pdf_report' }
    end
  end

  private

    def set_questionnaires
      @report.questionnaires = Questionnaire.list.where(pollable_type: 'ConclusionReview').pluck(:name, :id)
    end

    def create_pdf
      @pdf = Polls::ReviewPdf.new @report, current_organization
    end
end
