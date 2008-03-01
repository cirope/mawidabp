class InlineHelp < ActiveRecord::Base
  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Restricciones
  validates_presence_of :language, :name
  validates_uniqueness_of :name, :scope => :language, :allow_nil => true,
    :allow_blank => true
  validates_length_of :language, :maximum => 10, :allow_nil => true,
    :allow_blank => true
  validates_length_of :name, :maximum => 255, :allow_nil => true,
    :allow_blank => true
end