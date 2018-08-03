module Polls::AnswersHelper
  def show_poll? poll
    poll.answers.any? { |a| show_answer? a }
  end

  def show_answer? answer
    show_answer = show_question?(answer.question) && !@report.filter_answers

    show_answer ||
      @report.filter_answers &&
      @report.answer_option == answer.answer_option&.option
  end

  private

    def show_question? question
      if @report.question.present?
        question.question =~ /#{Regexp.escape @report.question}/i
      else
        true
      end
    end
end
