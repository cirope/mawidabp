module QuestionnairesHelper
  def questions
    @questionnaire.questions.build if @questionnaire.questions.empty?

    @questionnaire.questions
  end

  def pollable_types
    Questionnaire::POLLABLE_TYPES.map do |type|
      [type.constantize.model_name.human, type]
    end
  end

  def answer_type_options
    [
      [AnswerWritten.model_name.human(count: 1), Question::ANSWER_TYPES[:written]],
      [AnswerMultiChoice.model_name.human(count: 1), Question::ANSWER_TYPES[:multi_choice]],
      [AnswerYesNo.model_name.human(count: 1), Question::ANSWER_TYPES[:yes_no]]
    ]
  end
end
