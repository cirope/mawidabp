class NotificationRelation < ActiveRecord::Base
  include ParameterSelector
  include Associations::DestroyPaperTrail

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Relaciones
  belongs_to :notification
  belongs_to :model, -> { readonly }, :polymorphic => true, :primary_key => :id
end
