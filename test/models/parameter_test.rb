require 'test_helper'

# Clase para probar el modelo "Parameter"
class ParameterTest < ActiveSupport::TestCase
  fixtures :parameters, :organizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @parameter = Parameter.find parameters(:parameter_security_acount_expire_time).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_parameter = parameters(:parameter_security_acount_expire_time)
    assert_kind_of Parameter, @parameter
    assert_equal fixture_parameter.name, @parameter.name
    assert_equal fixture_parameter.value, @parameter.value
    assert_equal fixture_parameter.description, @parameter.description
    assert_equal fixture_parameter.organization, @parameter.organization
  end

  # Prueba la creación de un parámetro
  test 'create' do
    assert_difference 'Parameter.count' do
      @parameter = Parameter.create(
        :name => "new_parameter_#{rand(1000000000000)}",
        :value => 'xx',
        :description => 'New description',
        :organization_id => organizations(:default_organization).id
      )
    end
  end

  # Prueba de actualización de un parámetro
  test 'update' do
    assert_no_difference 'Parameter.count' do
      assert @parameter.update(:value => 'new_value'),
        @parameter.errors.full_messages.join('; ')
      @parameter.reload
    end

    assert_equal 'new_value', @parameter.value
  end

  # Prueba de eliminación de un parámetro
  test 'delete' do
    # En realidad no se permite eliminar parámetros por lo que esto nunca va a
    # pasar
    assert_difference 'Parameter.count', -1 do
      @parameter.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @parameter.name = nil
    @parameter.value = nil
    @parameter.organization_id = nil
    assert @parameter.invalid?
    assert_equal 3, @parameter.errors.count
    assert_equal [error_message_from_model(@parameter, :name, :blank)],
      @parameter.errors[:name]
    assert_equal [error_message_from_model(@parameter, :value, :blank)],
      @parameter.errors[:value]
    assert_equal [error_message_from_model(@parameter, :organization_id,
        :blank)], @parameter.errors[:organization_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @parameter.name = 'abcdd' * 21
    assert @parameter.invalid?
    assert_equal 1, @parameter.errors.count
    assert_equal [error_message_from_model(@parameter, :name, :too_long,
      :count => 100)], @parameter.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @parameter.name = '?123'
    assert @parameter.invalid?
    assert_equal 1, @parameter.errors.count
    assert_equal [error_message_from_model(@parameter, :name, :invalid)],
      @parameter.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    admin_aproach_types = parameters(:parameter_security_acount_expire_time)

    parameter = Parameter.new(
      :name => admin_aproach_types.name,
      :value => admin_aproach_types.value,
      :organization_id => admin_aproach_types.organization_id
    )

    assert parameter.invalid?
    assert_equal 1, parameter.errors.count
    assert_equal [error_message_from_model(parameter, :name, :taken)],
      parameter.errors[:name]
  end

  test 'find parameter' do
    parameter = Parameter.find_parameter(
      organizations(:default_organization).id, :security_attempts_count,
      Date.today)

    assert_not_nil parameter
    assert_equal parameters(:parameter_security_attempts_count).value,
      parameter

    parameter = Parameter.find_parameter(
      organizations(:default_organization).id, :fake_parameter_name, Date.today)

    assert_nil parameter
  end
end
