class ControlObjectiveWeaknessTemplateRelation < ApplicationRecord
  include Auditable

  validates :control_objective, presence: true

  belongs_to :control_objective
  belongs_to :weakness_template
end
