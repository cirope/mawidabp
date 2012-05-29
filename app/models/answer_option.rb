class AnswerOption < ActiveRecord::Base
  # Validaciones
  validates :question, :option, :presence => true
  validates_length_of :option, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  belongs_to :question
  has_many :answer_multi_choice
end
