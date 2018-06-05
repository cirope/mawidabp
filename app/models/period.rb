class Period < ApplicationRecord
  include Auditable
  include ParameterSelector
  include Periods::DateColumns
  include Periods::DestroyValidation
  include Periods::Overrides
  include Periods::Scopes
  include Periods::Validation

  belongs_to :organization
  has_one :plan
  has_many :reviews
  has_many :risk_assessments
  has_many :workflows
end
