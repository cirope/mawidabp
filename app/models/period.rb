class Period < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include Periods::DestroyValidation
  include Periods::Overrides
  include Periods::Scopes
  include Periods::Validation

  belongs_to :organization
  has_many :plans
  has_many :procedure_controls
  has_many :reviews
  has_many :workflows
end
