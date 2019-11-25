class BestPractice < ApplicationRecord
  include Auditable
  include BestPractices::AttributeTypes
  include BestPractices::Csv
  include BestPractices::Defaults
  include BestPractices::DestroyValidation
  include BestPractices::Json
  include BestPractices::ProcessControls
  include BestPractices::Search
  include BestPractices::Shared
  include BestPractices::Validations
  include ParameterSelector
  include Shareable

  belongs_to :group
  belongs_to :organization
end
