module Polls::Reports
  extend ActiveSupport::Concern

  included do
    before_action :auth, :set_current_module, :set_report, :set_date_range,
      :set_questionnaire, :set_user, :set_business_unit, :set_questionnaires,
      :set_title, :process_report

    respond_to :html, :js
  end

  def polls_calification polls
    count = total = 0

    polls_answered(polls).each do |poll|
      poll.answers.each do |answer|
        if answer.answer_option.present?
          value  = Question::ANSWER_OPTION_VALUES[answer.answer_option.option.to_sym]

          if value >= 0
            count += value
            total += 1
          end
        end
      end
    end

    total == 0 ? 0 : (count / total).round
  end

  def polls_answered polls
    polls.select { |p| p.answered == true }
  end

  private

    def set_current_module
      @current_module = 'administration_questionnaires_reports'
    end

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

    def set_user
      if params[:index] && params[:index][:user_option].present?
        @report.user_options = {
          only_all:        params[:index][:user_option] == 'only_all',
          include_reviews: params[:index][:user_option] == 'include_reviews'
        }
      end

      if params[:index] && params[:index][:user_id].present?
        @report.user_id = params[:index][:user_id]
      end
    end

    def set_business_unit
      if params[:index] && params[:index][:business_unit].present?
        @report.business_unit = params[:index][:business_unit]
      end

      if params[:index] && params[:index][:business_unit_type].present?
        @report.business_unit = params[:index][:business_unit_type]
      end
    end
end
