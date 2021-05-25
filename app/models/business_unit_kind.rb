class BusinessUnitKind < ApplicationRecord
  include Auditable
  include BusinessUnitKinds::Scopes
  include BusinessUnitKinds::DestroyValidation
  include BusinessUnitKinds::Validation

  belongs_to :organization
  has_many :business_units, dependent: :restrict_with_error

  def to_s
    name
  end
end
