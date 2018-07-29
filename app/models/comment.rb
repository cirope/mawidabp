class Comment < ApplicationRecord
  include ParameterSelector

  has_paper_trail meta: {
    organization_id: ->(model) { Current.organization.id }
  }

  # Restricciones
  validates :comment, :presence => true

  # Relaciones
  belongs_to :commentable, :polymorphic => true, :optional => true
  belongs_to :user
end
