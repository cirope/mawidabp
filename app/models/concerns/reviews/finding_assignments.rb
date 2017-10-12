module Reviews::FindingAssignments
  extend ActiveSupport::Concern

  included do
    has_many :finding_review_assignments,
      dependent:  :destroy,
      inverse_of: :review,
      after_add:  :check_if_fra_is_in_a_final_review

    accepts_nested_attributes_for :finding_review_assignments, allow_destroy: true
  end

  private

    def check_if_fra_is_in_a_final_review finding_review_assignment
      finding_review_assignment.finding.tap do |f|
        if f && !f.is_in_a_final_review?
          raise 'The finding must be in a final review'
        end
      end
    end
end
