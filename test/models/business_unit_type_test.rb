require 'test_helper'

# Clase para probar el modelo "BusinessUnitType"
class BusinessUnitTypeTest < ActiveSupport::TestCase
  fixtures :business_unit_types

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @business_unit_type = BusinessUnitType.find business_unit_types(:cycle).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of BusinessUnitType, @business_unit_type
    assert_equal business_unit_types(:cycle).name, @business_unit_type.name
    assert_equal business_unit_types(:cycle).business_unit_label,
      @business_unit_type.business_unit_label
    assert_equal business_unit_types(:cycle).project_label,
      @business_unit_type.project_label
  end

  # Prueba la creación de un grupo
  test 'create' do
    assert_difference 'BusinessUnitType.count' do
      @business_unit_type = BusinessUnitType.create(
        :name => 'New business unit type',
        :business_unit_label => 'New business unit label',
        :project_label => 'New project label',
        :external => false
      )
    end
  end

  # Prueba de actualización de un grupo
  test 'update' do
    assert @business_unit_type.update(:name => 'Updated name'),
      @business_unit_type.errors.full_messages.join('; ')
    @business_unit_type.reload
    assert_equal 'Updated name', @business_unit_type.name
  end

  # Prueba de eliminación de un grupo
  test 'delete' do
    assert_no_difference('BusinessUnitType.count') {@business_unit_type.destroy}

    assert !@business_unit_type.can_be_destroyed?

    assert_difference 'BusinessUnitType.count', -1 do
      BusinessUnitType.find(business_unit_types(:bcra).id).destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @business_unit_type.name = ' '
    @business_unit_type.business_unit_label = ' '

    assert @business_unit_type.invalid?
    assert_error @business_unit_type, :name, :blank
    assert_error @business_unit_type, :business_unit_label, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @business_unit_type.name = 'abcdd' * 52
    @business_unit_type.business_unit_label = 'abcdd' * 52
    @business_unit_type.project_label = 'abcdd' * 52

    assert @business_unit_type.invalid?
    assert_error @business_unit_type, :name, :too_long, count: 255
    assert_error @business_unit_type, :business_unit_label, :too_long, count: 255
    assert_error @business_unit_type, :project_label, :too_long, count: 255
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @business_unit_type.name = business_unit_types(:bcra).name

    assert @business_unit_type.invalid?
    assert_error @business_unit_type, :name, :taken
  end

  test 'validates business units that can not be destroyed' do
    @business_unit_type.business_units.each do |bu|
      bu.mark_for_destruction unless bu.can_be_destroyed?
    end

    assert @business_unit_type.invalid?
    assert_error @business_unit_type, :business_units, :locked
  end
end
