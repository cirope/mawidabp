# frozen_string_literal: true

require 'test_helper'

class AuxiliarBusinessUnitTypeTest < ActiveSupport::TestCase
  test 'remove all scored businessUnit after destroy' do
    Current.organization = organizations :cirope

    plan_item_one            = plan_items :current_plan_item_2
    business_unit_type_cycle = business_unit_types :cycle

    auxiliar_business_unit_type                    = AuxiliarBusinessUnitType.new
    auxiliar_business_unit_type.plan_item          = plan_item_one
    auxiliar_business_unit_type.business_unit_type = business_unit_type_cycle

    auxiliar_business_unit_type.save!

    control_objective_item = control_objective_items :management_dependency_item_editable
    control_objective_item.update! scored_business_unit_type: business_unit_type_cycle

    plan_item_one.auxiliar_business_unit_types.destroy auxiliar_business_unit_type

    control_objective_item.reload

    assert control_objective_item.scored_business_unit_type.blank?
  ensure
    Current.organization = nil
  end
end
