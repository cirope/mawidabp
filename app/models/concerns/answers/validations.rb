module Answers::Validations
  extend ActiveSupport::Concern

  included do
    TYPES = ['AnswerMultiChoice', 'AnswerWritten', 'AnswerYesNo']

    validates :type, inclusion: { in: TYPES }, allow_nil: true,
      allow_blank: true
    validate :answer_options, on: :update
  end

  private

    def answer_options
      should_have_answer = question.answer_multi_choice? ||
                           question.answer_yes_no?

      if should_have_answer && answer_option.blank?
        errors.add(:answer_option, :blank)
      end
    end
end
