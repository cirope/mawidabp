class Backup < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  validates_presence_of :backup_type
  validates_inclusion_of :backup_type, :in => [0, 1], :allow_nil => true,
    :allow_blank => true
end