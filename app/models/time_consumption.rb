class TimeConsumption < ApplicationRecord
  include Auditable
  include TimeConsumptions::AttributeTypes
  include TimeConsumptions::Scopes
  include TimeConsumptions::Validation

  belongs_to :user
  belongs_to :activity, inverse_of: :time_consumptions
end
