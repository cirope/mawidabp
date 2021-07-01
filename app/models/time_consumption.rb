class TimeConsumption < ApplicationRecord
  include Auditable
  include TimeConsumptions::AttributeTypes
  include TimeConsumptions::Scopes
  include TimeConsumptions::Validation

  belongs_to :user
  belongs_to :resource_on, polymorphic: true

  def to_s
    name
  end
end
