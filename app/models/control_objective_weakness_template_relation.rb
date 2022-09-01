class ControlObjectiveWeaknessTemplateRelation < ApplicationRecord
  include Auditable

  validates :control_objective, presence: true,
                                uniqueness: { scope: :weakness_template }

  belongs_to :control_objective
  belongs_to :weakness_template
end
