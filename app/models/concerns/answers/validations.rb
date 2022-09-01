module Answers::Validations
  extend ActiveSupport::Concern

  included do
    TYPES = ['AnswerMultiChoice', 'AnswerWritten', 'AnswerYesNo']

    validates :type, inclusion: { in: TYPES }, allow_nil: true,
      allow_blank: true
    validate :answer_written, on: :update
  end

  private

    def answer_written
      if question&.answer_written? && answer.length > 255
        errors.add :answer, :too_long, count: 255
      end
    end
end
