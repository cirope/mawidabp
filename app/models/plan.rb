class Plan < ApplicationRecord
  include Auditable
  include ParameterSelector
  include Plans::Clone
  include Plans::DestroyValidation
  include Plans::Duplication
  include Plans::Overload
  include Plans::PDF
  include Plans::PlanItems
  include Plans::Scopes
  include Plans::Units
  include Plans::ValidationCallbacks
  include Plans::Validations

  attr_readonly :period_id

  belongs_to :period
  belongs_to :organization
  has_one :risk_assessment, dependent: :nullify
end
