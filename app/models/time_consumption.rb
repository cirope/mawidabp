class TimeConsumption < ApplicationRecord
  include Auditable
  include TimeConsumptions::AttributeTypes
  include TimeConsumptions::Scopes
  include TimeConsumptions::Validation

  belongs_to :user
  belongs_to :resource, polymorphic: true, optional: false, inverse_of: :resource

  def to_s
    name
  end
end
