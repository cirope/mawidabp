class AnswerYesNo < Answer
  validates :answer_option, presence: true, on: :update
end

