class AnswerWritten < Answer
  # Validaciones
  validates :answer, :presence => true, :if => :poll_answered?
  validates_length_of :answer, :maximum => 255, :allow_nil => true, 
    :allow_blank => true
end
