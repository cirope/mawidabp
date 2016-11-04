class FindingUserAssignment < ActiveRecord::Base
  include Auditable
  include Comparable

  # Scopes
  scope :owners, -> { where(:process_owner => true) }
  scope :responsibles, -> { where(:responsible_auditor => true) }

  # Callbacks
  before_save :can_be_modified?, :assign_finding_type

  # Restricciones
  validates :user_id, :presence => true
  validates :user_id, :numericality => {:only_integer => true},
    :allow_blank => true, :allow_nil => true
  validates_each :process_owner do |record, attr, value|
    organization_id = record.finding.try(:organization_id)

    if value && !record.user.can_act_as_audited? && !record.user.can_act_as_audited_on?(organization_id)
      record.errors.add attr, :invalid
    end
  end
  validates_each :user_id do |record, attr, value|
    users = (record.finding || record.raw_finding).finding_user_assignments.
      reject(&:marked_for_destruction?).map(&:user_id)

    record.errors.add attr, :taken if users.select { |u| u == value }.size > 1
  end

  # Relaciones
  belongs_to :finding, :inverse_of => :finding_user_assignments,
    :polymorphic => true
  belongs_to :raw_finding, :foreign_key => :finding_id, :class_name => 'Finding'
  belongs_to :user

  def <=>(other)
    if other.kind_of?(FindingUserAssignment) && self.finding_id == other.finding_id
      self.user_id <=> other.user_id
    else
      -1
    end
  end

  def ==(other)
    other.kind_of?(FindingUserAssignment) && other.id &&
      (self.id == other.id || (self <=> other) == 0)
  end

  def can_be_modified?
    (self.finding || self.raw_finding).can_be_modified?
  end

  def assign_finding_type
    self.finding_type = self.finding.try(:type) || self.raw_finding.try(:type)
  end
end
