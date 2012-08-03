class AnswerMultiChoice < Answer
  # Validaciones
  validates :answer_option, :presence => true, :on => :update

end
