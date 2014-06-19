module Answers::Validations
  extend ActiveSupport::Concern

  included do
    TYPES = ['AnswerMultiChoice', 'AnswerWritten']

    validate :answer_options, on: :update
    validates :comments, length: { maximum: 255 },
      allow_nil: true, allow_blank: true
    validates :type, inclusion: { in: TYPES }, allow_nil: true,
      allow_blank: true
  end

  private

    def answer_options
      if question.answer_multi_choice? && answer_option.blank?
        errors.add(:answer_option_id, :blank)
      end
    end
end
