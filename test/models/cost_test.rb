require 'test_helper'

# Clase para probar el modelo "Cost"
class CostTest < ActiveSupport::TestCase
  fixtures :costs

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @cost = Cost.find costs(:hardware_rent).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Cost, @cost
    assert_equal costs(:hardware_rent).description, @cost.description
    assert_equal costs(:hardware_rent).cost, @cost.cost
    assert_equal costs(:hardware_rent).item_id, @cost.item_id
    assert_equal costs(:hardware_rent).item_type, @cost.item_type
    assert_equal costs(:hardware_rent).cost_type, @cost.cost_type
    assert_equal costs(:hardware_rent).user_id, @cost.user_id
  end

  # Prueba la creación de un costo
  test 'create' do
    assert_difference 'Cost.count' do
      @cost = Cost.create(
        description: 'New description',
        cost: '15.50',
        cost_type: 'audit',
        item: findings(:unconfirmed_weakness),
        user: users(:administrator)
      )
    end

    assert_equal 'New description', @cost.reload.description
  end

  # Prueba de actualización de un costo
  test 'update' do
    assert @cost.update(description: 'Updated description'),
      @cost.errors.full_messages.join('; ')
    @cost.reload
    assert_equal 'Updated description', @cost.description
  end

  # Prueba de eliminación de costos
  test 'destroy' do
    assert_difference('Cost.count', -1) { @cost.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @cost.cost = '  '
    @cost.item_id = nil
    @cost.item_type = '   '
    @cost.cost_type = '   '
    @cost.user_id = nil

    assert @cost.invalid?
    assert_error @cost, :cost, :blank
    assert_error @cost, :item_id, :blank
    assert_error @cost, :item_type, :blank
    assert_error @cost, :cost_type, :blank
    assert_error @cost, :user_id, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @cost.cost = '12-9'
    @cost.item_id = '12.2'
    @cost.user_id = '15.4'

    assert @cost.invalid?
    assert_error @cost, :cost, :not_a_number
    assert_error @cost, :item_id, :not_an_integer
    assert_error @cost, :user_id, :not_an_integer
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates attributes boundaries' do
    @cost.cost = '-1'
    assert @cost.invalid?

    assert_error @cost, :cost, :greater_than_or_equal_to, count: 0
  end

  test 'fetch the correct time from raw cost' do
    assert_not_equal 1, @cost.cost.round

    @cost.raw_cost = '1h 15m'
    assert_in_delta 1.25, @cost.cost, 0.0001

    @cost.raw_cost = '15m'
    assert_in_delta 0.25, @cost.cost, 0.0001

    @cost.raw_cost = '1:15'
    assert_in_delta 1.25, @cost.cost, 0.0001

    @cost.raw_cost = ':15'
    assert_in_delta 0.25, @cost.cost, 0.0001
  end
end
