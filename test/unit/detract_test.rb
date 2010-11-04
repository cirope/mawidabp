require 'test_helper'

# Clase para probar el modelo "Detract"
class DetractTest < ActiveSupport::TestCase
  fixtures :detracts

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @detract = Detract.find detracts(
      :adequate_for_administrator_in_default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Detract, @detract
    assert_equal detracts(:adequate_for_administrator_in_default_organization).
      value, @detract.value
    assert_equal detracts(:adequate_for_administrator_in_default_organization).
      observations, @detract.observations
    assert_equal detracts(:adequate_for_administrator_in_default_organization).
      user_id, @detract.user_id
    assert_equal detracts(:adequate_for_administrator_in_default_organization).
      organization_id, @detract.organization_id
  end

  # Prueba la creación de un detracto
  test 'create' do
    assert_difference 'Detract.count' do
      @detract = Detract.create(
        :value => 0.65,
        :observations => 'New observations',
        :user => users(:administrator_user),
        :organization => organizations(:default_organization)
      )
    end

    assert_equal 'New observations', @detract.reload.observations
  end

  # Prueba de actualización de un detracto
  test 'update' do
    assert @detract.update_attributes(:observations => 'Updated observations'),
      @detract.errors.full_messages.join('; ')
    @detract.reload
    assert_equal 'Updated observations', @detract.observations
  end

  # Prueba de eliminación de detractos
  test 'destroy' do
    assert_difference('Detract.count', -1) { @detract.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @detract.value = '  '
    @detract.user_id = nil
    assert @detract.invalid?
    assert_equal 2, @detract.errors.count
    assert_equal [error_message_from_model(@detract, :value, :blank)],
      @detract.errors[:value]
    assert_equal [error_message_from_model(@detract, :user_id, :blank)],
      @detract.errors[:user_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @detract.value = '12-9'
    assert @detract.invalid?
    assert_equal 1, @detract.errors.count
    assert_equal [error_message_from_model(@detract, :value, :not_a_number)],
      @detract.errors[:value]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates attributes boundaries' do
    @detract.value = '-0.01'
    assert @detract.invalid?
    assert_equal 1, @detract.errors.count
    assert_equal [error_message_from_model(@detract, :value,
      :greater_than_or_equal_to, :count => 0)], @detract.errors[:value]

    @detract.reload

    @detract.value = '1.01'
    assert @detract.invalid?
    assert_equal 1, @detract.errors.count
    assert_equal [error_message_from_model(@detract, :value,
      :less_than_or_equal_to, :count => 1)], @detract.errors[:value]
  end
end