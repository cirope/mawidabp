class BestPractice < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include Associations::DestroyPaperTrail
  include Associations::DestroyInBatches
  include BestPractices::Defaults
  include BestPractices::Validations
  include BestPractices::Scopes
  include BestPractices::ProcessControls

  belongs_to :group
  belongs_to :organization
end
