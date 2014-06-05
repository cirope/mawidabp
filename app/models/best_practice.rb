class BestPractice < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include BestPractices::DestroyValidation
  include BestPractices::Validations
  include BestPractices::Scopes
  include BestPractices::ProcessControls

  belongs_to :organization
end
