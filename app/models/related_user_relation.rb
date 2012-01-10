class RelatedUserRelation < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }
  
  # Restricciones
  validates :related_user, :presence => true
  validates :related_user_id, :uniqueness => { :scope => :user_id }
  
  # Relaciones
  belongs_to :user
  belongs_to :related_user, :class_name => 'User'
end