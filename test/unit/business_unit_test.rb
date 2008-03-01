require 'test_helper'

# Clase para probar el modelo "BusinessUnit"
class BusinessUnitTest < ActiveSupport::TestCase
  fixtures :business_units

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @business_unit = BusinessUnit.find business_units(:business_unit_one).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of BusinessUnit, @business_unit
    assert_equal business_units(:business_unit_one).name, @business_unit.name
    assert_equal business_units(:business_unit_one).organization_id,
      @business_unit.organization_id
  end

  # Prueba la creación de una unidad de negocio
  test 'create' do
    assert_difference 'BusinessUnit.count' do
      @business_unit = BusinessUnit.new(
        :name => 'New name',
        :business_unit_type => BusinessUnit::TYPES[:cycle],
        :organization => organizations(:default_organization)
      )

      assert @business_unit.save, @business_unit.errors.full_messages.join('; ')
      assert_equal 'New name', @business_unit.name
    end
  end

  # Prueba de actualización de una unidad de negocio
  test 'update' do
    assert @business_unit.update_attributes(:name => 'Updated name'),
      @business_unit.errors.full_messages.join('; ')
    @business_unit.reload
    assert_equal 'Updated name', @business_unit.name
  end

  # Prueba de eliminación de unidades de negocio
  test 'destroy' do
    assert_no_difference('BusinessUnit.count') { @business_unit.destroy }

    assert_equal 1, @business_unit.errors.size
    assert_equal I18n.t(:'organization.errors.business_unit_related'),
      @business_unit.errors.full_messages.first

    assert_difference 'BusinessUnit.count', -1 do
      BusinessUnit.find(business_units(:business_unit_four)).destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @business_unit.name = ' '
    @business_unit.business_unit_type = nil
    assert @business_unit.invalid?
    assert_equal 2, @business_unit.errors.count
    assert_equal error_message_from_model(@business_unit, :name, :blank),
      @business_unit.errors.on(:name)
    assert_equal error_message_from_model(@business_unit, :business_unit_type,
      :blank), @business_unit.errors.on(:business_unit_type)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @business_unit.business_unit_type = BusinessUnit::TYPES.values.sort.last.next
    assert @business_unit.invalid?
    assert_equal 1, @business_unit.errors.count
    assert_equal error_message_from_model(@business_unit, :business_unit_type,
      :inclusion), @business_unit.errors.on(:business_unit_type)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @business_unit.name = 'abcdd' * 52
    assert @business_unit.invalid?
    assert_equal 1, @business_unit.errors.count
    assert_equal error_message_from_model(@business_unit, :name, :too_long,
      :count => 255), @business_unit.errors.on(:name)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @business_unit.name = business_units(:business_unit_two).name
    assert @business_unit.invalid?
    assert_equal 1, @business_unit.errors.count
    assert_equal error_message_from_model(@business_unit, :name, :taken),
      @business_unit.errors.on(:name)
  end

  test 'dynamic functions' do
    BusinessUnit::TYPES.each do |type, value|
      @business_unit.business_unit_type = value
      assert @business_unit.send("#{type}?".to_sym)

      (BusinessUnit::TYPES.values - [value]).each do |v|
        @business_unit.business_unit_type = v
        assert !@business_unit.send("#{type}?".to_sym)
      end
    end
  end
end