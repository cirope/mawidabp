class RelatedUserRelation < ActiveRecord::Base
  include Associations::DestroyPaperTrail

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Restricciones
  validates :related_user, :presence => true
  validates :related_user_id, :uniqueness => { :scope => :user_id }

  # Relaciones
  belongs_to :user
  belongs_to :related_user, :class_name => 'User'
end
