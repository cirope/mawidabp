class Poll < ActiveRecord::Base
  # Validaciones
  validates :questionnaire, :presence => true
  validates_length_of :comments, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  belongs_to :questionnaire
  has_many :answers
end
