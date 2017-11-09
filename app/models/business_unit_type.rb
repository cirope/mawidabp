class BusinessUnitType < ApplicationRecord
  include Auditable
  include BusinessUnitTypes::DestroyValidation
  include BusinessUnitTypes::JSON
  include BusinessUnitTypes::Scopes
  include BusinessUnitTypes::Validations
  include Trimmer

  trimmed_fields :name, :business_unit_label, :project_label

  alias_attribute :label, :name

  belongs_to :organization
  has_many :business_units, -> { order name: :asc }, dependent: :destroy

  accepts_nested_attributes_for :business_units, allow_destroy: true
end
