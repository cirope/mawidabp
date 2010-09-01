class ResourceUtilization < ActiveRecord::Base
  include ParameterSelector
  include Comparable

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Named scopes
  scope :human, :conditions => { :resource_type => 'User' }
  scope :material, :conditions => { :resource_type => 'Resource' }

  # Restricciones
  validates :units, :cost_per_unit, :resource_id, :resource_type,
    :presence => true
  validates_numericality_of :resource_id, :resource_consumer_id,
    :only_integer => true, :allow_nil => true, :allow_blank => true
  validates_numericality_of :units, :cost_per_unit, :allow_nil => true,
    :allow_blank => true, :greater_than_or_equal_to => 0
  validate :check_resource_consumer

  # Relaciones
  belongs_to :resource, :polymorphic => true
  belongs_to :resource_consumer, :polymorphic => true

  def <=>(other)
    self.resource_id <=> other.resource_id
  end

  def check_resource_consumer
    if self.changed? && self.resource_consumer.respond_to?(:is_frozen?) &&
        self.resource_consumer.is_frozen?
      self.errors.add :resource_consumer, :is_frozen
    else
      true
    end
  end

  def cost
    (self.units || 0) * (self.cost_per_unit || 0)
  end

  def human?
    self.resource_type == 'User'
  end

  def material?
    self.resource_type == 'Resource'
  end
end