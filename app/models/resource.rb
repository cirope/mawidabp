class Resource < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Restricciones
  validates_presence_of :name
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_uniqueness_of :name, :case_sensitive => false,
    :scope => :resource_class_id
  validates_numericality_of :cost_per_unit, :greater_than_or_equal_to => 0,
    :allow_nil => true
  validates_numericality_of :resource_class_id, :only_integer => true,
    :allow_nil => true
  
  # Relaciones
  belongs_to :resource_class
  has_many :users, :dependent => :nullify
  has_many :resource_utilizations, :as => :resource, :dependent => :destroy

  def to_s
    self.name
  end

  alias_method :resource_name, :to_s
end