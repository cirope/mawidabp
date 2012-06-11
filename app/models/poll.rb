class Poll < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  # Validaciones
  validates_length_of :comments, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  belongs_to :questionnaire
  belongs_to :user
  has_many :answers, :dependent => :destroy
  
  accepts_nested_attributes_for :answers
  
  def initialize(attributes = nil, options = {})
    super(attributes, options)
    
    if self.questionnaire && self.answers.empty?
      self.questionnaire.questions.each do |question|
        self.answers.build(:question => question)
      end
    end
  end
end
