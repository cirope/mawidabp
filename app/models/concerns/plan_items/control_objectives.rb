module PlanItems::ControlObjectives
  extend ActiveSupport::Concern

  included do
    has_many :control_objective_projects, dependent: :destroy

    accepts_nested_attributes_for :control_objective_projects,
      allow_destroy: true, reject_if: :all_blank
  end
end
