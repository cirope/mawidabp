require 'test_helper'

class AuxiliarBusinessUnitTypeTest < ActiveSupport::TestCase
  test 'invalid because repeated' do
    aux_but_new                    = AuxiliarBusinessUnitType.new
    aux_but_new.plan_item          = plan_items(:current_plan_item_1)
    aux_but_new.business_unit_type = business_unit_types(:consolidated_substantive)

    refute aux_but_new.valid?
  end
end
