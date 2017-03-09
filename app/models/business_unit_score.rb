class BusinessUnitScore < ApplicationRecord
  include Auditable
  include BusinessUnitScores::Effectiveness
  include BusinessUnitScores::Validation

  belongs_to :business_unit
  belongs_to :control_objective_item
end
