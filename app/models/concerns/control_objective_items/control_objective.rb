module ControlObjectiveItems::ControlObjective
  extend ActiveSupport::Concern

  included do
    delegate :support, :support?, to: :control_objective
    delegate :process_control, to: :control_objective, allow_nil: true

    belongs_to :control_objective, inverse_of: :control_objective_items
  end
end
