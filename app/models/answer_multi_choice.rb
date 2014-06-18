class AnswerMultiChoice < Answer
  validates :answer_option, presence: true, on: :update
end
