class FindingReviewAssignment < ApplicationRecord
  include Auditable
  include FindingReviewAssignments::Comparable
  include FindingReviewAssignments::Validations

  belongs_to :finding, inverse_of: :finding_review_assignments
  belongs_to :review
end
