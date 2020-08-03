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

    def set_polls
      @report.polls = Poll.list.
        between_dates(@report.from_date.at_beginning_of_day, @report.to_date.end_of_day, @report.date_field).
        by_questionnaire(@report.questionnaire).
        by_user(@report.user_id, **Hash(@report.user_options))

      @report.polls = @report.polls.by_question(@report.question) unless @report.question.nil?
      @report.polls = @report.polls.answered(@report.answered) unless @report.answered.nil?

      if ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced'
        @report.polls = Poll.where id: @report.polls.ids.uniq
      end
    end

    def create_pdf
      @pdf = Polls::ReviewPdf.new @report, current_organization
    end
end
