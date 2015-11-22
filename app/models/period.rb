class Period < ActiveRecord::Base
  include Auditable
  include ParameterSelector
  include Comparable
  include Associations::DestroyPaperTrail
  include Associations::DestroyInBatches
  include Periods::Overrides
  include Periods::Scopes
  include Periods::Validation

  belongs_to :organization
  has_many :plans, dependent: :destroy
  has_many :reviews
  has_many :workflows
end
