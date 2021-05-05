class TimeConsumption < ApplicationRecord
  include Auditable
  include TimeConsumptions::Scopes
  include TimeConsumptions::Validation

  belongs_to :user
  belongs_to :activity
end
