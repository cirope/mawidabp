module Answers::Completed
  extend ActiveSupport::Concern

  def completed?
    if question&.answer_written?
      answer.present?
    elsif question&.answer_multi_choice? || question&.answer_yes_no?
      answer_option.present?
    end
  end
end
