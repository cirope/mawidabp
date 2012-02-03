class EMail < ActiveRecord::Base
  has_paper_trail
  
  attr_accessible :to, :subject, :body, :attachments, :organization_id
  
  # Scopes
  scope :ordered_list, lambda {
    where(
      :organization_id => GlobalModelConfig.current_organization_id
    ).order('created_at DESC')
  }
  
  # Restricciones
  validates :to, :subject, :presence => true
  
  # Relaciones
  belongs_to :organization
end
