class BusinessUnitKind < ApplicationRecord
  include Auditable
  include BusinessUnitKinds::Validation

  def to_s
    name
  end
end
