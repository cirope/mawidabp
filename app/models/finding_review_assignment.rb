class FindingReviewAssignment < ActiveRecord::Base
  include Comparable
  include Associations::DestroyPaperTrail

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Restricciones
  validates :finding_id, :presence => true
  validates :finding_id, :numericality => {:only_integer => true},
    :allow_blank => true, :allow_nil => true
  validates_each :finding_id do |record, attr, value|
    findings = record.review.finding_review_assignments.reject(
      &:marked_for_destruction?).map(&:finding_id)

    record.errors.add attr, :taken if findings.select {|u| u == value}.size > 1
  end

  # Relaciones
  belongs_to :finding, :inverse_of => :finding_review_assignments
  belongs_to :review

  def <=>(other)
    if self.finding_id == other.finding_id
      self.review_id <=> other.review_id
    else
      -1
    end
  end

  def ==(other)
    other.kind_of?(FindingReviewAssignment) && other.id &&
      (self.id == other.id || (self <=> other) == 0)
  end
end
