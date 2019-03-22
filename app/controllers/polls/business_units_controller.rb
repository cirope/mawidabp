class Polls::BusinessUnitsController < ApplicationController
  include Polls::Reports

  def index
    respond_to do |format|
      format.html
      format.js { create_pdf and render 'shared/pdf_report' }
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
        @report.cr = ConclusionFinalReview.list_all_by_date(@from_date.months_ago(3), @to_date)
        filter_cr parameters

        if @report.cr.present?
          if @report.selected_business_unit
            polls_business_unit
          else
            polls_business_unit_type
          end
        end
      end
    end

    def filter_cr parameters
      filter_by_selected_business_unit
      filter_by_parameter_business_unit parameters
    end

    def filter_by_parameter_business_unit parameters
      if parameters[:business_unit].present?
        business_units = parameters[:business_unit].split(SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)

        if business_units.present?
          @report.cr = @report.cr.by_business_unit_names(*business_units)
        end
      end
    end

    def filter_by_selected_business_unit
      if @report.selected_business_unit
        @report.cr = @report.cr.by_business_unit_type(@report.selected_business_unit.id)
      end
    end

    def set_polls
      Poll.list.
        between_dates(@from_date.at_beginning_of_day, @to_date.end_of_day, @report.date_field).
        by_questionnaire(@report.questionnaire).
        by_user(@report.user_id, @report.user_options || {}).
        pollables
    end

    def but_polls business_unit
      set_polls.select do |poll|
        poll.pollable.review.plan_item.business_unit.business_unit_type == business_unit
      end
    end

    def polls_business_unit
      polls = but_polls @report.selected_business_unit
      if polls.present?
        @report.business_unit_polls[@report.selected_business_unit.name] = results(polls)
      end
    end

    def polls_business_unit_type
      BusinessUnitType.list.each do |but|
        polls = but_polls but
        @report.business_unit_polls[but.name] = results(polls) if polls.present?
      end
    end

    def results polls
      rates, answered, unanswered = @report.questionnaire.answer_rates(polls)
      {
        rates: rates,
        answered: answered,
        unanswered: unanswered,
        calification: polls_calification(polls)
      }
    end

    def create_pdf
      @pdf = Polls::BusinessUnitPdf.new @report, current_organization
    end
end
