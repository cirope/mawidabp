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

    def set_polls
      @report.polls = Poll.list.
        between_dates(@report.from_date.at_beginning_of_day, @report.to_date.end_of_day, @report.date_field).
        by_questionnaire(@report.questionnaire).
        by_user(@report.user_id, **Hash(@report.user_options))

      @report.polls = @report.polls.by_question(@report.question) unless @report.question.nil?
      @report.polls = @report.polls.answered(@report.answered) unless @report.answered.nil?
      @report.polls = @report.polls.answer_option(@report.answer_option) unless @report.answer_option.nil?

      if ActiveRecord::Base.connection.adapter_name == 'OracleEnhanced'
        @report.polls = Poll.where id: @report.polls.ids.uniq
      end
    end
end
