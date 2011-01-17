class FindingUserAssignment < ActiveRecord::Base
  include Comparable

  has_paper_trail :meta => {
    :organization_id => Proc.new { GlobalModelConfig.current_organization_id }
  }

  # Restricciones
  validates :user_id, :presence => true
  validates :user_id, :numericality => {:only_integer => true},
    :allow_blank => true, :allow_nil => true
  validates_each :user_id do |record, attr, value|
    users = record.finding.finding_user_assignments.reject(
      &:marked_for_destruction?).map(&:user_id)
    
    record.errors.add attr, :taken if users.select { |u| u == value }.size > 1
  end

  # Relaciones
  belongs_to :finding, :inverse_of => :finding_user_assignments
  belongs_to :user

  def <=>(other)
    if self.finding_id == other.finding_id
      self.user_id <=> other.user_id
    else
      -1
    end
  end

  def ==(other)
    other.kind_of?(FindingUserAssignment) && other.id &&
      (self.id == other.id || (self <=> other) == 0)
  end
end