module ReviewUserAssignments::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      joins(review: :organization).where(review: {
        organization_id: Current.organization&.id
      }).order identification: :asc
    }
  end

  module ClassMethods
    def audit_team
      where assignment_type: [
        ReviewUserAssignment::TYPES[:auditor],
        ReviewUserAssignment::TYPES[:supervisor],
        ReviewUserAssignment::TYPES[:manager],
        ReviewUserAssignment::TYPES[:responsible]
      ]
    end
  end
end
