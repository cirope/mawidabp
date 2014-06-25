module Polls::Reports
  extend ActiveSupport::Concern

  included do
    before_action :auth, :check_privileges
    before_action :set_report, :set_date_range, :set_questionnaire, :set_questionnaires,
      :set_title, :process_report, :set_pdf_report

    respond_to :html, :js
  end

  def polls_calification polls
    count = total = 0
    polls_answered(polls).each do |poll|
      poll.answers.each do |answer|
        if answer.answer_option.present?
          count += Question::ANSWER_OPTION_VALUES[answer.answer_option.option.to_sym]
          total += 1
        end
      end
    end
    total == 0 ? 0 : (count / total).round
  end

  def polls_answered polls
    polls.select { |p| p.answered == true }
  end

  private

    def set_report
      @report = OpenStruct.new params: params
    end

    def set_date_range
      @from_date, @to_date = *make_date_range(params[:index])
      @report.from_date = @from_date
      @report.to_date = @to_date
    end

    def set_questionnaire
      if params[:index] && params[:index][:questionnaire].present?
        @report.questionnaire = Questionnaire.find(params[:index][:questionnaire])
      end
    end
end
