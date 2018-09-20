module Questionnaires::Answers
  extend ActiveSupport::Concern

  def answer_rates polls
    rates = ActiveSupport::OrderedHash.new

    questions.each do |question|
      rates[question.question] = []

      if question.options.any?
        question.options.each { rates[question.question] << 0 }
      else
        rates[question.question] << 0
      end
    end

    rates = polls_answers polls, rates
    rates = polls_questions polls, rates

    return rates, polls_answered(polls).count, polls_unanswered(polls).count
  end

  private

    def polls_answered polls
      # Warning: don't use where
      polls.select { |p| p.answered == true }
    end

    def polls_unanswered polls
      # Warning: don't use where
      polls.select { |p| p.answered == false }
    end

    def polls_answers polls, rates
      polls_answered(polls).each do |poll|
        poll.answers.each do |answer|
          options = answer.question&.options

          if options.present? && answer.answer_option
            option = options.rindex answer.answer_option.option.to_sym

            rates[answer.question.question][option] += 1 if option
          elsif options.blank? && answer.answer.present? && answer.question
            rates[answer.question.question][0] += 1
          end
        end
      end

      rates
    end

    def polls_questions polls, rates
      answered = polls_answered(polls).count

      questions.each do |question|
        text = question.question

        if question.options.any?
          question.options.each_index do |i|
            if answered > 0
              rates[text][i] = ((rates[text][i] / answered.to_f) * 100).round 2
            else
              rates[text][i] = 0
            end
          end
        elsif answered > 0
          rates[text][0] = ((rates[text][0] / answered.to_f) * 100).round 2
        end
      end

      rates
    end
end
