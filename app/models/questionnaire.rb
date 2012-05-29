class Questionnaire < ActiveRecord::Base
  # Validaciones
  validates :name, :presence => true
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  has_many :poll
  has_many :questions
end
