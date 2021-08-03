# frozen_string_literal: true

require 'test_helper'

class AuxiliarBusinessUnitTest < ActiveSupport::TestCase
  test 'remove all scored businessUnit after destroy' do
    plan_item_one     = plan_items :current_plan_item_1
    business_unit_two = business_units :business_unit_two

    auxiliar_business_unit               = AuxiliarBusinessUnit.new
    auxiliar_business_unit.plan_item     = plan_item_one
    auxiliar_business_unit.business_unit = business_unit_two

    plan_item_one.auxiliar_business_units << auxiliar_business_unit
    plan_item_one.save

    control_objective_item = control_objective_items :management_dependency_item

    control_objective_item.scored_business_unit = business_unit_two
    control_objective_item.save

    plan_item_one.auxiliar_business_units.destroy auxiliar_business_unit

    control_objective_item.reload

    assert control_objective_item.scored_business_unit.blank?
  end
end
