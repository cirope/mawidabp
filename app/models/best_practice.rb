class BestPractice < ApplicationRecord
  include Auditable
  include BestPractices::Defaults
  include BestPractices::DestroyValidation
  include BestPractices::ProcessControls
  include BestPractices::Search
  include BestPractices::Validations
  include ParameterSelector
  include Shareable

  belongs_to :group
  belongs_to :organization
end
