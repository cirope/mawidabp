class AnswerWritten < Answer
  validates :answer, presence: true, on: :update
  validates :answer, length: { maximum: 255 }, allow_nil: true,
    allow_blank: true
end
