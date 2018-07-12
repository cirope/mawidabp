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

    def set_answer_option
      if params[:index] && params[:index][:answer_option].present?
        @report.answer_option = params[:index][:answer_option]
      end

      if params[:index] && params[:index][:filter_answers].present?
        @report.filter_answers = params[:index][:filter_answers] == '1'
      end
    end

    def set_questionnaires
      @report.questionnaires = Questionnaire.list.pluck(:name, :id)
    end

    def process_report
      set_answered
      set_answer_option

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
        by_user(@report.user_id, @report.user_options || {})

      @report.polls = @report.polls.answered(@report.answered) unless @report.answered.nil?
      @report.polls = @report.polls.answer_option(@report.answer_option) unless @report.answer_option.nil?
    end

    def create_pdf
      @pdf = Polls::AnswerPDF.new @report, current_organization
    end
end
