class Comment < ActiveRecord::Base
  include ParameterSelector
  include PaperTrail::DependentDestroy

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Restricciones
  validates :comment, :presence => true

  # Relaciones
  belongs_to :commentable, :polymorphic => true
  belongs_to :user
end
