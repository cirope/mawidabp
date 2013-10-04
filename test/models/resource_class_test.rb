require 'test_helper'

# Clase para probar el modelo "ResourceClass"
class ResourceClassTest < ActiveSupport::TestCase
  fixtures :resource_classes

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @resource_class = ResourceClass.find resource_classes(:human_resources).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ResourceClass, @resource_class
    assert_equal resource_classes(:human_resources).name, @resource_class.name
    assert_equal resource_classes(:human_resources).unit, @resource_class.unit
  end

  # Prueba la creación de una clase de recurso
  test 'create' do
    assert_difference 'ResourceClass.count' do
      ResourceClass.create(
        :name => 'New resource class',
        :unit => get_test_parameter(:admin_resource_units).first[1],
        :resource_class_type => ResourceClass::TYPES[:human],
        :organization => organizations(:default_organization)
      )
    end
  end

  # Prueba de actualización de una clase de recurso
  test 'update' do
    assert @resource_class.update(:name => 'Updated resource_class'),
      @resource_class.errors.full_messages.join('; ')
    @resource_class.reload
    assert_equal 'Updated resource_class', @resource_class.name
  end

  # Prueba de eliminación de clases de recursos
  test 'delete' do
    assert_difference('ResourceClass.count', -1) { @resource_class.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @resource_class.name = '?_1'
    @resource_class.unit = '1.55'
    assert @resource_class.invalid?
    assert_equal 2, @resource_class.errors.count
    assert_equal [error_message_from_model(@resource_class, :name, :invalid)],
      @resource_class.errors[:name]
    assert_equal [error_message_from_model(@resource_class, :unit,
      :not_an_integer)], @resource_class.errors[:unit]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @resource_class.name = nil
    @resource_class.unit = '  '
    assert @resource_class.invalid?
    assert_equal 2, @resource_class.errors.count
    assert_equal [error_message_from_model(@resource_class, :name, :blank)],
      @resource_class.errors[:name]
    assert_equal [error_message_from_model(@resource_class, :unit, :blank)],
      @resource_class.errors[:unit]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @resource_class.name = 'abcdd' * 52
    assert @resource_class.invalid?
    assert_equal 1, @resource_class.errors.count
    assert_equal [error_message_from_model(@resource_class, :name, :too_long,
      :count => 255)], @resource_class.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @resource_class.name = resource_classes(:hardware_resources).name
    assert @resource_class.invalid?
    assert_equal 1, @resource_class.errors.count
    assert_equal [error_message_from_model(@resource_class, :name, :taken)],
      @resource_class.errors[:name]

    @resource_class.organization_id = organizations(:second_organization).id
    assert @resource_class.valid?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @resource_class.resource_class_type =
      ResourceClass::TYPES.values.sort.last.next
    assert @resource_class.invalid?
    assert_equal 1, @resource_class.errors.count
    assert_equal [error_message_from_model(@resource_class,
        :resource_class_type, :inclusion)],
      @resource_class.errors[:resource_class_type]
  end

  test 'dynamic functions' do
    ResourceClass::TYPES.each do |type, value|
      @resource_class.resource_class_type = value
      assert @resource_class.send("#{type}?".to_sym)

      (ResourceClass::TYPES.values - [value]).each do |v|
        @resource_class.resource_class_type = v
        assert !@resource_class.send("#{type}?".to_sym)
      end
    end
  end
end
