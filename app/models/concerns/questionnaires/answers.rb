module Questionnaires::Answers
  extend ActiveSupport::Concern

  def answer_rates polls
    rates = ActiveSupport::OrderedHash.new

    questions.each do |question|
      rates[question.question] = []
      Question::ANSWER_OPTIONS.each { rates[question.question] << 0 }
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
      polls.each do |poll|
        poll.answers.each do |answer|
          if answer.answer_option
            option = Question::ANSWER_OPTIONS.rindex answer.answer_option.option.to_sym
            rates[answer.question.question][option] += 1
          end
        end
      end

      rates
    end

    def polls_questions polls, rates
      questions.each do |question|
        question = question.question
        Question::ANSWER_OPTIONS.each_index do |i|
          if (answered = polls_answered(polls).count) > 0
            rates[question][i] = ((rates[question][i] / answered.to_f) * 100).round 2
          else
            rates[question][i] = 0
          end
        end
      end

      rates
    end
end
