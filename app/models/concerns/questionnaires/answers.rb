module Questionnaires::Answers
  extend ActiveSupport::Concern

  def answer_rates(polls)
    rates = ActiveSupport::OrderedHash.new
    questions.each do |question|
      rates[question.question] ||= []
      Question::ANSWER_OPTIONS.each do
        rates[question.question] << 0
      end
    end

    answered = 0
    unanswered = 0
    polls.each do |poll|
      if poll.answered
        answered += 1
        poll.answers.each do |answer|
          # Si es múltiple opción
          if answer.answer_option
            option = Question::ANSWER_OPTIONS.rindex answer.answer_option.option.to_sym
            rates[answer.question.question][option] += 1
          end
        end
      else
        unanswered +=1
      end
    end

    questions.each do |question|
      question = question.question
      Question::ANSWER_OPTIONS.each_index do |i|
        unless answered == 0
          rates[question][i] = ((rates[question][i] / answered.to_f) * 100).round 2
        else
          rates[question][i] = 0
        end
      end
    end

    return rates, answered, unanswered
  end
end
