class BusinessUnitKind < ApplicationRecord
  include Auditable
  include BusinessUnitKinds::Scopes
  include BusinessUnitKinds::Validation

  belongs_to :organization
  has_many :business_units

  def to_s
    name
  end
end
