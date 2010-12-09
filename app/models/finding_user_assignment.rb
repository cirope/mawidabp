class FindingUserAssignment < ActiveRecord::Base
  include Comparable

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Restricciones
  validates :user_id, :presence => true
  validates :user_id, :numericality => {:only_integer => true},
    :allow_blank => true, :allow_nil => true

  # Relaciones
  belongs_to :finding
  belongs_to :user

  def <=>(other)
    self.user_id.to_i <=> other.user_id.to_i
  end
end