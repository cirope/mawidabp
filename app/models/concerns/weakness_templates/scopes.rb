module WeaknessTemplates::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Organization.current_id }
  end

  module ClassMethods
    def by_control_objective control_objective
      left_joins(:control_objectives).
        where(control_objectives: { id: control_objective.id }).
        references(:control_objectives)
    end
  end
end
