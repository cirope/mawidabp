class HelpContent < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => proc { |i| GlobalModelConfig.current_organization_id }
  }
  
  # Restricciones
  validates :language, :presence => true
  validates :language, :length => {:maximum => 10}, :allow_nil => true,
    :allow_blank => true
  validates :language, :uniqueness => {:case_sensitive => false},
    :allow_blank => true, :allow_nil => true

  # Relaciones
  has_many :help_items, :dependent => :destroy, :order => 'order_number ASC'

  accepts_nested_attributes_for :help_items, :allow_destroy => true
end