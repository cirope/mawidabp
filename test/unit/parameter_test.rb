require 'test_helper'

# Clase para probar el modelo "Parameter"
class ParameterTest < ActiveSupport::TestCase
  fixtures :parameters, :organizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @parameter = Parameter.find parameters(:parameter_admin_aproach_types).id
    FileUtils.rm_r File.join(Rails.root, 'tmp', 'cache_files'), :force => true
  end

  def teardown
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_parameter = parameters(:parameter_admin_aproach_types)
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
      assert @parameter.update_attributes(:value => 'new_value'),
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
    assert_equal error_message_from_model(@parameter, :name, :blank),
      @parameter.errors[:name]
    assert_equal error_message_from_model(@parameter, :value, :blank),
      @parameter.errors[:value]
    assert_equal error_message_from_model(@parameter, :organization_id, :blank),
      @parameter.errors[:organization_id]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @parameter.name = 'abcdd' * 21
    assert @parameter.invalid?
    assert_equal 1, @parameter.errors.count
    assert_equal error_message_from_model(@parameter, :name, :too_long,
      :count => 100), @parameter.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @parameter.name = '?123'
    assert @parameter.invalid?
    assert_equal 1, @parameter.errors.count
    assert_equal error_message_from_model(@parameter, :name, :invalid),
      @parameter.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    admin_aproach_types = parameters(:parameter_admin_aproach_types)

    parameter = Parameter.new(
      :name => admin_aproach_types.name,
      :value => admin_aproach_types.value,
      :organization_id => admin_aproach_types.organization_id
    )

    assert parameter.invalid?
    assert_equal 1, parameter.errors.count
    assert_equal error_message_from_model(parameter, :name, :taken),
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

  test 'find in cache before and after find parameter' do
    now = Time.now
    parameter = Parameter.find_in_cache(
      organizations(:default_organization).id, :security_attempts_count, now)

    assert_nil parameter
    
    parameter = Parameter.find_parameter(
      organizations(:default_organization).id, :security_attempts_count, now)

    assert_not_nil parameter

    parameter = Parameter.find_in_cache(
      organizations(:default_organization).id, :security_attempts_count, now)

    assert_not_nil parameter

    assert parameter.update_attributes(:description => 'Updated description')

    parameter = Parameter.find_in_cache(
      organizations(:default_organization).id, :security_attempts_count,
      Time.now)

    assert_not_nil parameter
    assert_equal 'Updated description', parameter.description
  end

  test 'write and read from cache' do
    parameter = nil
    versions_dates = [30.days.ago, 10.days.ago, 1.day.ago]

    assert_difference 'Parameter.count' do
      parameter = Parameter.create(
        :name => 'parameter_for_test',
        :value => -1,
        :organization_id => organizations(:default_organization).id
      )
    end


    Parameter.record_timestamps = false

    versions_dates.each_with_index do |date, i|
      assert parameter.update_attributes(:value => i, :updated_at => date)

      Parameter.write_in_cache parameter
    end

    parameter = Parameter.find_in_cache(organizations(:default_organization).id,
      'parameter_for_test', 1.hour.ago)

    assert_not_nil parameter
    assert_equal versions_dates.last, parameter.updated_at
    assert_equal 2, parameter.value

    parameter = Parameter.find_in_cache(organizations(:default_organization).id,
      'parameter_for_test', 9.days.ago)
    
    assert_not_nil parameter
    assert_equal versions_dates.second, parameter.updated_at
    assert_equal 1, parameter.value

    parameter = Parameter.find_in_cache(organizations(:default_organization).id,
      'parameter_for_test', 11.days.ago)

    assert_not_nil parameter
    assert_equal versions_dates.first, parameter.updated_at
    assert_equal 0, parameter.value

    assert_no_difference 'Parameter.count' do
      versions_dates << 3.days.ago
      versions_dates.sort!

      assert parameter.reload.update_attributes(
        :value => versions_dates.size,
        :updated_at => versions_dates[-2]
      )

      Parameter.write_in_cache parameter
    end

    Parameter.record_timestamps = true

    parameter = Parameter.find_in_cache(organizations(:default_organization).id,
      'parameter_for_test', 2.days.ago)

    assert_not_nil parameter
    assert_equal versions_dates[-2], parameter.updated_at
    assert_equal versions_dates.size, parameter.value
  end
end