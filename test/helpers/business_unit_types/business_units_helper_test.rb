# frozen_string_literal: true

require 'test_helper'

class BusinessUnitTypes::BusinessUnitsHelperTest < ActionView::TestCase
  test 'Should business unit types' do
    set_organization

    expected = BusinessUnitType.list.map { |but| [but.name, but.id] }

    assert_equal expected, business_unit_types
  end
end
