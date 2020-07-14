class BusinessUnitType < ApplicationRecord
  include Auditable
  include BusinessUnitTypes::AttributeTypes
  include BusinessUnitTypes::BusinessUnits
  include BusinessUnitTypes::DestroyValidation
  include BusinessUnitTypes::Json
  include BusinessUnitTypes::Scopes
  include BusinessUnitTypes::Validations
  include Trimmer

  trimmed_fields :name, :business_unit_label, :project_label

  alias_attribute :label, :name

  belongs_to :organization
  has_many :users, -> { readonly }, through: :business_unit_type_users

  def to_s
    name
  end
end
