class Control < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Relaciones
  belongs_to :controllable, :polymorphic => true

  def initialize(attributes = nil)
    super(attributes)

    self.order ||= 1
  end
end