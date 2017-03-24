module FindingReviewAssignments::Comparable
  extend ActiveSupport::Concern
  include ::Comparable

  def <=> other
    if other.kind_of?(FindingReviewAssignment) && finding_id == other.finding_id
      review_id <=> other.review_id
    else
      -1
    end
  end

  def == other
    other.kind_of?(FindingReviewAssignment) &&
      other.id &&
      (id == other.id || (self <=> other) == 0)
  end
end
