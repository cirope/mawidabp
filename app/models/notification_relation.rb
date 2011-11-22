class NotificationRelation < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => proc { |i| GlobalModelConfig.current_organization_id }
  }
  
  # Relaciones
  belongs_to :notification
  belongs_to :model, :polymorphic => true, :readonly => true,
    :primary_key => :id
end