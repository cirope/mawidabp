class EMail < ActiveRecord::Base
  has_paper_trail
  
  attr_accessible :to, :subject, :body, :attachments
  
  # Restricciones
  validates :to, :subject, :presence => true
end
