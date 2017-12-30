class BusinessUnitType < ApplicationRecord
  include Auditable
  include BusinessUnitTypes::BusinessUnits
  include BusinessUnitTypes::DestroyValidation
  include BusinessUnitTypes::JSON
  include BusinessUnitTypes::Scopes
  include BusinessUnitTypes::Validations
  include Trimmer

  trimmed_fields :name, :business_unit_label, :project_label

  alias_attribute :label, :name

  belongs_to :organization
end
