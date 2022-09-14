module Questions::AnswerTypeName
  extend ActiveSupport::Concern

  def answer_type_name
    if answer_yes_no?
      AnswerYesNo.name
    elsif answer_multi_choice?
      AnswerMultiChoice.name
    elsif answer_written?
      AnswerWritten.name
    end
  end
end
