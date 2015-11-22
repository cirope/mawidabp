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
end
