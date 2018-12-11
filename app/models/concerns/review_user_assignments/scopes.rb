module ReviewUserAssignments::Scopes
  extend ActiveSupport::Concern

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
