class Comment < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Restricciones
  validates_presence_of :comment

  # Relaciones
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
end