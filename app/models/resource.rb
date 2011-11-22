class Resource < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => proc { |i| GlobalModelConfig.current_organization_id }
  }

  # Restricciones
  validates :name, :presence => true
  validates :name, :length => {:maximum => 255}, :allow_nil => true,
    :allow_blank => true
  validates :name, :uniqueness =>
    {:case_sensitive => false, :scope => :resource_class_id}
  validates :cost_per_unit, :numericality => {:greater_than_or_equal_to => 0},
    :allow_nil => true
  validates :resource_class_id, :numericality => {:only_integer => true},
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