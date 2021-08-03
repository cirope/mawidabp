# frozen_string_literal: true

require 'test_helper'

class AuxiliarBusinessUnitTest < ActiveSupport::TestCase
  test 'remove all scored businessUnit after destroy' do
    plan_item_one     = plan_items :current_plan_item_2
    business_unit_two = business_units :business_unit_two

    auxiliar_business_unit               = AuxiliarBusinessUnit.new
    auxiliar_business_unit.plan_item     = plan_item_one
    auxiliar_business_unit.business_unit = business_unit_two

    auxiliar_business_unit.save!

    control_objective_item = control_objective_items :management_dependency_item_editable
    control_objective_item.update_attribute 'scored_business_unit_id', business_unit_two.id

    assert control_objective_item.scored_business_unit.present?

    plan_item_one.auxiliar_business_units.destroy auxiliar_business_unit

    control_objective_item.reload

    assert control_objective_item.scored_business_unit.blank?
  end
end
