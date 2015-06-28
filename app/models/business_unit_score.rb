class BusinessUnitScore < ActiveRecord::Base
  include Auditable
  include BusinessUnitScores::Validation

  belongs_to :business_unit
  belongs_to :control_objective_item
end
