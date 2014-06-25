class Polls::BusinessUnitsController < ApplicationController
  include Polls::Reports

  def index
    if request.xhr?
      @pdf = Polls::BusinessUnitPdf.new @report, current_organization
    end

    respond_to do |format|
      format.html
      format.js { render 'shared/pdf_report' }
    end
  end

  private

    def set_questionnaires
      @report.questionnaires = Questionnaire.list.pollable.pluck(:name, :id)
    end

    def process_report
      @report.business_unit_polls = {}
      parameters = params[:index]

      if parameters
        @report.selected_business_unit = BusinessUnitType.find_by id: parameters[:business_unit_type]
        conclusion_reviews = set_conclusion_reviews(parameters)

        if conclusion_reviews.present?
          filtered_polls = set_polls.select { |poll| conclusion_reviews.include? poll.pollable }

          if @report.selected_business_unit
            polls_business_unit filtered_polls
          else
            polls_business_unit_type
          end
        end
      end
    end

    def set_conclusion_reviews parameters
      conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from_date.months_ago(3), @to_date)

      if @report.selected_business_unit
        conclusion_reviews = conclusion_reviews.by_business_unit_type(@report.selected_business_unit.id)
      end

      if parameters[:business_unit].present?
        business_units = parameters[:business_unit].split(SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)

        if business_units.present?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(*business_units)
        end
      end

      conclusion_reviews
    end

    def set_polls
      Poll.between_dates(@from_date.at_beginning_of_day, @to_date.end_of_day).
        by_questionnaire(@report.questionnaire).pollables
    end

    def polls_business_unit filtered_polls
      but_polls = filtered_polls.select { |poll|
        poll.pollable.review.plan_item.business_unit.business_unit_type == @report.selected_business_unit
      }

      if but_polls.present?
        @report.business_unit_polls[@report.selected_business_unit.name] = {}
        rates, answered, unanswered = @report.questionnaire.answer_rates(but_polls)
        @report.business_unit_polls[@report.selected_business_unit.name][:rates] = rates
        @report.business_unit_polls[@report.selected_business_unit.name][:answered] = answered
        @report.business_unit_polls[@report.selected_business_unit.name][:unanswered] = unanswered
        @report.business_unit_polls[@report.selected_business_unit.name][:calification] = polls_calification(but_polls)
      end
    end

    def polls_business_unit_type
      BusinessUnitType.list.each do |but|
        but_polls = set_polls.select { |poll|
          poll.pollable.review.plan_item.business_unit.business_unit_type == but
        }
        if but_polls.present?
          @report.business_unit_polls[but.name] = {}
          rates, answered, unanswered = @report.questionnaire.answer_rates(but_polls)
          @report.business_unit_polls[but.name][:rates] = rates
          @report.business_unit_polls[but.name][:answered] = answered
          @report.business_unit_polls[but.name][:unanswered] = unanswered
          @report.business_unit_polls[but.name][:calification] = polls_calification(but_polls)
        end
      end
    end
end
