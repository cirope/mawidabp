class AnswerMultiChoice < Answer
  def completed?
    answer_option.present?
  end
end
