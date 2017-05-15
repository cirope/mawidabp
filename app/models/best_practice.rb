class BestPractice < ApplicationRecord
  include Auditable
  include BestPractices::Defaults
  include BestPractices::DestroyValidation
  include BestPractices::Validations
  include BestPractices::ProcessControls
  include ParameterSelector
  include Shareable

  belongs_to :group
  belongs_to :organization
end
