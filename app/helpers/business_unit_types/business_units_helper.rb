# frozen_string_literal: true

module BusinessUnitTypes::BusinessUnitsHelper
  def business_unit_types
    BusinessUnitType.list.map { |but| [but.name, but.id] }
  end
end
