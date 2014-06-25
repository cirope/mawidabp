class PollReports
  attr_accessor :questionnaires, :polls, :questionnaire, :rates,
    :answered, :unanswered, :calification, :selected_business_unit,
    :business_unit_polls, :filter, :from, :to, :params

  def initialize params, from = nil, to = nil
    @params, @from, @to = params, from, to

    @filter = params[:filter]
  end

  private

    def process_filter
      case @filter
        when 'business_unit' then process_business_unit
        when 'answers'       then process_answers
      end
    end

    def process_business_unit
      @questionnaires = Questionnaire.list.pollable.map { |q| [q.name, q.id.to_s] }
      @business_unit_polls = {}
      parameters = @params[:reports]

      if parameters
        @questionnaire = Questionnaire.find_by id: parameters[:questionnaire]
        @selected_business_unit = BusinessUnitType.find_by id: parameters[:business_unit_type]
        conclusion_reviews = load_conclusion_reviews(parameters)

        if conclusion_reviews.present?
          filtered_polls = load_polls.select { |poll| conclusion_reviews.include? poll.pollable }

          if @selected_business_unit
            polls_business_unit filtered_polls
          else
            polls_business_unit_type
          end
        end
      end
    end

    def load_conclusion_reviews parameters
      conclusion_reviews = ConclusionFinalReview.list_all_by_date(@from.months_ago(3), @to)

      if @selected_business_unit
        conclusion_reviews = conclusion_reviews.by_business_unit_type(@selected_business_unit.id)
      end

      if parameters[:business_unit].present?
        business_units = parameters[:business_unit].split(SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)

        if business_units.present?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(*business_units)
        end
      end

      conclusion_reviews
    end

    def load_polls
      Poll.between_dates(@from.at_beginning_of_day, @to.end_of_day).
        by_questionnaire(@questionnaire).pollables
    end

    def polls_business_unit filtered_polls
      but_polls = filtered_polls.select { |poll|
        poll.pollable.review.plan_item.business_unit.business_unit_type == @selected_business_unit
      }

      if but_polls.present?
        @business_unit_polls[@selected_business_unit.name] = {}
        rates, answered, unanswered = @questionnaire.answer_rates(but_polls)
        @business_unit_polls[@selected_business_unit.name][:rates] = rates
        @business_unit_polls[@selected_business_unit.name][:answered] = answered
        @business_unit_polls[@selected_business_unit.name][:unanswered] = unanswered
        @business_unit_polls[@selected_business_unit.name][:calification] = polls_calification(but_polls)
      end
    end

    def polls_business_unit_type
      BusinessUnitType.list.each do |but|
        but_polls = load_polls.select { |poll|
          poll.pollable.review.plan_item.business_unit.business_unit_type == but
        }
        if but_polls.present?
          @business_unit_polls[but.name] = {}
          rates, answered, unanswered = @questionnaire.answer_rates(but_polls)
          @business_unit_polls[but.name][:rates] = rates
          @business_unit_polls[but.name][:answered] = answered
          @business_unit_polls[but.name][:unanswered] = unanswered
          @business_unit_polls[but.name][:calification] = polls_calification(but_polls)
        end
      end
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
end
