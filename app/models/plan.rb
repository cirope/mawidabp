class Plan < ApplicationRecord
  include Auditable
  include ParameterSelector
  include Plans::Clone
  include Plans::Csv
  include Plans::CsvPrsPat
  include Plans::CsvPrhPat
  include Plans::DestroyValidation
  include Plans::Duplication
  include Plans::History
  include Plans::Overload
  include Plans::Pdf
  include Plans::PlanItems
  include Plans::Scopes
  include Plans::Status
  include Plans::Units
  include Plans::ValidationCallbacks
  include Plans::Validations

  attr_readonly :period_id

  belongs_to :period
  belongs_to :organization
  has_one :risk_assessment, dependent: :nullify
end
