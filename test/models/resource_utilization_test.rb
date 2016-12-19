require 'test_helper'

class ResourceUtilizationTest < ActiveSupport::TestCase
  def setup
    @resource_utilization =
      resource_utilizations(:auditor_for_20_units_plan_item_1)
  end

  test 'create' do
    assert_difference 'ResourceUtilization.count' do
      @resource_utilization = ResourceUtilization.create(
        units: '21.5',
        resource_consumer: plan_items(:current_plan_item_1),
        resource: resources(:senior_auditor_resource)
      )
    end
  end

  test 'update' do
    assert_in_delta 20, @resource_utilization.units, 0.01
    assert @resource_utilization.update(units: '22'),
      @resource_utilization.errors.full_messages.join('; ')

    assert_in_delta 22, @resource_utilization.reload.units, 0.01
  end

  test 'delete' do
    assert_difference 'ResourceUtilization.count', -1 do
      @resource_utilization.destroy
    end
  end

  test 'validates blank attributes' do
    @resource_utilization = ResourceUtilization.new units: ''

    assert @resource_utilization.invalid?
    assert_error @resource_utilization, :units, :blank
    assert_error @resource_utilization, :resource, :blank
  end

  test 'validates well formated attributes' do
    @resource_utilization.units = '_1'

    assert @resource_utilization.invalid?
    assert_error @resource_utilization, :units, :not_a_number
  end
end
