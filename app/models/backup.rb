class Backup < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  validates :backup_type, :presence => true
  validates :backup_type, :inclusion => { :in => [0, 1] }, :allow_nil => true,
    :allow_blank => true
end