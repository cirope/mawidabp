class AnswerWritten < Answer
  validates :answer, length: { maximum: 255 }, allow_nil: true,
    allow_blank: true

  def completed?
    answer.present?
  end
end
