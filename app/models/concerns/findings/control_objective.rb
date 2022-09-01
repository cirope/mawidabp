module Findings::ControlObjective
  extend ActiveSupport::Concern

  included do
    belongs_to :control_objective_item

    has_one :review, through: :control_objective_item
    has_one :control_objective, through: :control_objective_item
    has_one :business_unit, through: :review
    has_one :business_unit_type, through:  :business_unit
  end

  def design?
    control_objective_item&.design_score.present?
  end

  def compliance?
    control_objective_item&.compliance_score.present?
  end

  def sustantive?
    control_objective_item&.sustantive_score.present?
  end
end
