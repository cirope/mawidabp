class Answer < ActiveRecord::Base
  # Validaciones
  validates :question, :presence => true
  validates_length_of :comments, :maximum => 255, :allow_nil => true,
    :allow_blank => true

  # Relaciones
  belongs_to :question
  belongs_to :poll
end
