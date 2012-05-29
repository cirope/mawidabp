class AnswerMultiChoice < Answer
  # Validaciones
  validates :answer_option, :presence => true
  # Relaciones
  belongs_to :answer_option
end
