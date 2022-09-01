class AnswerYesNo < Answer
  def completed?
    answer_option.present?
  end
end
