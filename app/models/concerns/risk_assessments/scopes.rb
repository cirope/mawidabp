module RiskAssessments::Scopes
  extend ActiveSupport::Concern

  included do
    scope :organization_scoped, -> {
      where organization_id: Current.organization&.id,
            group_id:        Current.group&.id
    }
  end
end
