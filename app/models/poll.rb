class Poll < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  # Validaciones
  validates :questionnaire, :presence => true
  validates_length_of :comments, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  belongs_to :questionnaire
  has_many :answers, :dependent => :destroy
end
