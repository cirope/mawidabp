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

    def process_report
      set_question
      set_answered

      if @report.questionnaire
        set_polls
        @report.rates, @report.answered, @report.unanswered = @report.questionnaire.answer_rates @report.polls
        @report.calification = polls_calification(@report.polls)
      end
    end

    def create_pdf
      @pdf = Polls::ReviewPdf.new @report, current_organization
    end
end
