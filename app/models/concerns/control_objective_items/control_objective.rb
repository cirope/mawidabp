module ControlObjectiveItems::ControlObjective
  extend ActiveSupport::Concern

  included do
    belongs_to :control_objective, inverse_of: :control_objective_items
    has_one :process_control, through: :control_objective
    has_one :best_practice, through: :process_control
    has_many :tags, through: :control_objective
  end

  def original_text?
    control_objective_text&.squish == control_objective.name&.squish
  end
end
