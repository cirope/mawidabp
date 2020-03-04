class ControlObjectiveProject < ApplicationRecord
  include Auditable

  belongs_to :control_objective
  belongs_to :plan_item
end
