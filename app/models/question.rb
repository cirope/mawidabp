class Question < ActiveRecord::Base
  
  ANSWER_TYPES = [
    :written => 0,
    :multi_choice => 1
  ]
  # Validaciones
  validates :sort_order, :question, :answer_type, :presence => true
  validates_numericality_of :sort_order, :only_integer => true, :allow_nil => true,
    :allow_blank => true
  validates_length_of :question, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_inclusion :answer_type, :in => ANSWER_TYPES, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  has_many :answer_options
  has_many :answer
  belongs_to :questionnaire
end
