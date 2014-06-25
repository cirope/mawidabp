class Polls::QuestionnairesController < ApplicationController
  include Polls::Reports

  def index
    if request.xhr?
      @pdf = Polls::QuestionnairePdf.new @report, current_organization
    end

    respond_to do |format|
      format.html
      format.js { render 'shared/pdf_report' }
    end
  end

  private

    def set_questionnaires
      @report.questionnaires = Questionnaire.list.pluck(:name, :id)
    end

    def process_report
      if @report.questionnaire
        @report.polls = Poll.between_dates(@report.from_date.at_beginning_of_day, @report.to_date.end_of_day).
          by_questionnaire(@report.questionnaire)
        @report.rates, @report.answered, @report.unanswered = @report.questionnaire.answer_rates @report.polls
        @report.calification = polls_calification(@report.polls)
      end
    end
end
