class AnswerOption < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  # Validaciones
  validates :option, :presence => true
  validates_length_of :option, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  belongs_to :question
  has_many :answer_multi_choice
end
