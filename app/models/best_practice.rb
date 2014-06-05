class BestPractice < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include BestPractices::Validations
  include BestPractices::Scopes
  include BestPractices::ProcessControls
  include BestPractices::DestroyValidation

  belongs_to :organization
end
