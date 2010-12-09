class Detract < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Named scopes
  scope :for_organization, lambda { |organization|
    where(:organization_id => organization.id)
  }

  # Restricciones sobre los atributos
  attr_readonly :organization_id
  attr_protected :organization_id

  # Restricciones
  validates :value, :user_id, :presence => true
  validates :value, :numericality =>
    {:greater_than_or_equal_to => 0, :less_than_or_equal_to => 1},
    :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :user
  belongs_to :organization

  def initialize(attributes = nil)
    super(attributes)

    self.organization_id = GlobalModelConfig.current_organization_id
  end
end