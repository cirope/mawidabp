module Answers::Validations
  extend ActiveSupport::Concern

  included do
    TYPES = ['AnswerMultiChoice', 'AnswerWritten']

    validates :comments, length: { maximum: 255 },
      allow_nil: true, allow_blank: true
    validates :type, inclusion: { in: TYPES }, allow_nil: true,
      allow_blank: true
  end
end
