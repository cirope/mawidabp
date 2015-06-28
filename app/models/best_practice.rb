class BestPractice < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include BestPractices::Defaults
  include BestPractices::DestroyValidation
  include BestPractices::Validations
  include BestPractices::Scopes
  include BestPractices::ProcessControls

  belongs_to :group
  belongs_to :organization
end
