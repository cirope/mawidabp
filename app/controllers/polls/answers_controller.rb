class Polls::AnswersController < ApplicationController
  include Polls::Reports

  def index
    if request.xhr?
      @pdf = Polls::AnswerPdf.new @report, current_organization
    end

    respond_to do |format|
      format.html
      format.js { render 'shared/pdf_report' }
    end
  end

  private

    def set_answered
      if params[:index] && ['true', 'false'].include?(params[:index][:answered])
        @report.answered = params[:index][:answered] == 'true'
      end
    end

    def set_questionnaires
      @report.questionnaires = Questionnaire.list.pluck(:name, :id)
    end

    def process_report
      set_answered

      if @report.questionnaire
        @report.polls = Poll.between_dates(@report.from_date.at_beginning_of_day, @report.to_date.end_of_day).
          by_questionnaire(@report.questionnaire)
        @report.polls = @report.polls.answered(@report.answered) unless @report.answered.nil?
        @report.rates, @report.answered, @report.unanswered = @report.questionnaire.answer_rates @report.polls
        @report.calification = polls_calification(@report.polls)
      end
    end
end
