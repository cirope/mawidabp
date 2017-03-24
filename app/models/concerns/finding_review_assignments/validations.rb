module FindingReviewAssignments::Validations
  extend ActiveSupport::Concern

  included do
    validates :finding_id, presence: true
    validate :already_assigned
  end

  private

    def already_assigned
      finding_ids = review.finding_review_assignments.
        reject(&:marked_for_destruction?).
        map(&:finding_id)

      if finding_ids.select { |f_id| f_id == finding_id }.size > 1
        errors.add :finding_id, :taken
      end
    end
end
