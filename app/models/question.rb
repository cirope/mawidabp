class Question < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  ANSWER_TYPES = {
    :written => 0,
    :multi_choice => 1
  }
  ANSWER_OPTIONS = [
    :strongly_agree,    
    :agree,
    :neither_agree_nor_disagree,
    :disagree,    
    :strongly_disagree    
  ]  
  
  # Validaciones
  validates :sort_order, :question, :answer_type, :presence => true
  validates_numericality_of :sort_order, :only_integer => true, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :question, :allow_nil => true, :allow_blank => true
  validates_length_of :question, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_inclusion_of :answer_type, :in => ANSWER_TYPES.values, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  has_many :answer_options, :dependent => :destroy
  has_many :answer
  belongs_to :questionnaire
  
  ANSWER_TYPES.each do |answer_type, answer_value|
    define_method("answer_#{answer_type}?") { self.answer_type == answer_value }
  end

end
