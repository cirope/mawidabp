require 'test_helper'

# Clase para probar el modelo "ResourceUtilization"
class ResourceUtilizationTest < ActiveSupport::TestCase
  fixtures :resource_utilizations, :plan_items, :resources

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @resource_utilization = ResourceUtilization.find(
      resource_utilizations(:auditor_for_20_units_plan_item_1).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ResourceUtilization, @resource_utilization
    resource_utilization = resource_utilizations(
      :auditor_for_20_units_plan_item_1)
    assert_equal resource_utilization.units, @resource_utilization.units
    assert_equal resource_utilization.cost_per_unit,
      @resource_utilization.cost_per_unit
    assert_equal resource_utilization.resource_consumer_id,
      @resource_utilization.resource_consumer_id
    assert_equal resource_utilization.resource_id,
      @resource_utilization.resource_id
  end

  # Prueba la creación de una utilización de recursos
  test 'create' do
    assert_difference 'ResourceUtilization.count' do
      @resource_utilization = ResourceUtilization.create(
        :units => '21.5',
        :cost_per_unit => '1.23',
        :resource_consumer => plan_items(:current_plan_item_1),
        :resource => resources(:senior_auditor_resource)
      )
    end
  end

  # Prueba de actualización de una utilización de recursos
  test 'update' do
    assert_in_delta 20, @resource_utilization.units, 0.01
    assert @resource_utilization.update_attributes(:units => '22'),
      @resource_utilization.errors.full_messages.join('; ')
    @resource_utilization.reload
    assert_in_delta 22, @resource_utilization.units, 0.01
  end

  # Prueba de eliminación de utilizaciones de recursos
  test 'delete' do
    assert_difference 'ResourceUtilization.count', -1 do
      @resource_utilization.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @resource_utilization.units = nil
    @resource_utilization.cost_per_unit = ' '
    @resource_utilization.resource_id = '   '
    assert @resource_utilization.invalid?
    assert_equal 3, @resource_utilization.errors.count
    assert_equal error_message_from_model(@resource_utilization, :units,
      :blank), @resource_utilization.errors.on(:units)
    assert_equal error_message_from_model(@resource_utilization, :cost_per_unit,
      :blank), @resource_utilization.errors.on(:cost_per_unit)
    assert_equal error_message_from_model(@resource_utilization, :resource_id,
      :blank), @resource_utilization.errors.on(:resource_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @resource_utilization.units = '_1'
    @resource_utilization.cost_per_unit = '_1'
    @resource_utilization.resource_id = '12.5'
    @resource_utilization.resource_consumer_id = '1.5'
    assert @resource_utilization.invalid?
    assert_equal 4, @resource_utilization.errors.count
    assert_equal error_message_from_model(@resource_utilization, :units,
      :not_a_number), @resource_utilization.errors.on(:units)
    assert_equal error_message_from_model(@resource_utilization, :cost_per_unit,
      :not_a_number), @resource_utilization.errors.on(:cost_per_unit)
    assert_equal error_message_from_model(@resource_utilization, :resource_id,
      :not_a_number), @resource_utilization.errors.on(:resource_id)
    assert_equal error_message_from_model(@resource_utilization,
      :resource_consumer_id, :not_a_number),
      @resource_utilization.errors.on(:resource_consumer_id)
  end

  test 'cost function' do
    calculated_cost = @resource_utilization.cost_per_unit *
    @resource_utilization.units

    assert @resource_utilization.cost_per_unit > 1
    assert @resource_utilization.units > 1
    assert_in_delta calculated_cost, @resource_utilization.cost, 0.01
  end
end