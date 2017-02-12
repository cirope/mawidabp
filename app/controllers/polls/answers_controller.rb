class Polls::AnswersController < ApplicationController
  include Polls::Reports

  def index
    respond_to do |format|
      format.html
      format.js { create_pdf and render 'shared/pdf_report' }
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
        set_polls
        @report.rates, @report.answered, @report.unanswered = @report.questionnaire.answer_rates @report.polls
        @report.calification = polls_calification(@report.polls)
      end
    end

    def set_polls
      @report.polls = Poll.list.
        between_dates(@report.from_date.at_beginning_of_day, @report.to_date.end_of_day).
        by_questionnaire(@report.questionnaire).
        by_affected_user(@report.affected_user_id, only_all: @report.only_all)

      @report.polls = @report.polls.answered(@report.answered) unless @report.answered.nil?
    end

    def create_pdf
      @pdf = Polls::AnswerPDF.new @report, current_organization
    end
end
