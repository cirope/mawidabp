class HelpContent < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  # Restricciones
  validates_presence_of :language
  validates_length_of :language, :maximum => 10, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :language, :allow_blank => true, :allow_nil => true

  # Relaciones
  has_many :help_items, :dependent => :destroy, :order => 'order_number ASC'

  accepts_nested_attributes_for :help_items, :allow_destroy => true
end