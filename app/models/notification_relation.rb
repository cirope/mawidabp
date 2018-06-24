class NotificationRelation < ApplicationRecord
  include ParameterSelector

  has_paper_trail meta: {
    organization_id: ->(model) { Current.organization_id }
  }

  # Relaciones
  belongs_to :notification
  belongs_to :model, -> { readonly }, :polymorphic => true, :primary_key => :id
end
