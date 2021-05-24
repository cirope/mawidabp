class BusinessUnitKind < ApplicationRecord
  include Auditable
  include BusinessUnitKinds::Scopes
  include BusinessUnitKinds::Validation

  belongs_to :organization

  def to_s
    name
  end
end
