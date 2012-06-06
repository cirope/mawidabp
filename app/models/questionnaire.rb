class Questionnaire < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }  
  # Validaciones
  validates :name, :presence => true
  validates_uniqueness_of :name, :allow_nil => true, :allow_blank => true
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  # Relaciones
  has_many :poll
  has_many :questions, :dependent => :destroy,
    :order => "#{Question.table_name}.sort_order ASC"
  
  accepts_nested_attributes_for :questions, :allow_destroy => true
end
