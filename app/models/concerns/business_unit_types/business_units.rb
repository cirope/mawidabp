module BusinessUnitTypes::BusinessUnits
  extend ActiveSupport::Concern

  included do
    has_many :business_units, -> { order name: :asc }, dependent: :destroy

    accepts_nested_attributes_for :business_units, allow_destroy: true
  end
end
