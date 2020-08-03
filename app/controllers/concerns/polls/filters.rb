module Polls::Filters
  extend ActiveSupport::Concern

    def set_question
      if params[:index] && params[:index][:question].present?
        @report.question = params[:index][:question]
      end
    end

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
end
