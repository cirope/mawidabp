class Plan < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include Plans::Clone
  include Plans::Costs
  include Plans::DestroyValidation
  include Plans::Duplication
  include Plans::Overload
  include Plans::Pdf
  include Plans::PlanItems
  include Plans::Scopes
  include Plans::ValidationCallbacks
  include Plans::Validations

  attr_readonly :period_id

  belongs_to :period
  belongs_to :organization
end
