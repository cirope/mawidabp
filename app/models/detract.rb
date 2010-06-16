class Detract < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Restricciones
  validates_presence_of :value
  validates_numericality_of :value, :greater_than_or_equal_to => 0,
    :less_than_or_equal_to => 1, :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :user
  belongs_to :organization
end