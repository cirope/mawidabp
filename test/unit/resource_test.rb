require 'test_helper'

# Clase para probar el modelo "Resource"
class ResourceTest < ActiveSupport::TestCase
  fixtures :resources, :resource_classes

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @resource = Resource.find resources(:auditor_resource).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Resource, @resource
    assert_equal resources(:auditor_resource).name, @resource.name
    assert_equal resources(:auditor_resource).description, @resource.description
    assert_equal resources(:auditor_resource).cost_per_unit,
      @resource.cost_per_unit
  end

  # Prueba la creación de un recurso
  test 'create' do
    assert_difference 'Resource.count' do
      Resource.create(
        :name => 'New name',
        :description => 'New description',
        :cost_per_unit => '12.5',
        :resource_class => resource_classes(:human_resources)
      )
    end
  end

  # Prueba de actualización de un recurso
  test 'update' do
    assert @resource.update_attributes(:description => 'Updated resource'),
      @resource.errors.full_messages.join('; ')
    @resource.reload
    assert_equal 'Updated resource', @resource.description
  end

  # Prueba de eliminación de recursos
  test 'delete' do
    assert_difference('Resource.count', -1) { @resource.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @resource.resource_class_id = '1.2'
    @resource.cost_per_unit = '_1'
    assert @resource.invalid?
    assert_equal 2, @resource.errors.count
    assert_equal error_message_from_model(@resource, :resource_class_id,
      :not_a_number), @resource.errors[:resource_class_id]
    assert_equal error_message_from_model(@resource, :cost_per_unit,
      :not_a_number), @resource.errors[:cost_per_unit]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @resource.name = ''
    assert @resource.invalid?
    assert_equal 1, @resource.errors.count
    assert_equal error_message_from_model(@resource, :name, :blank),
      @resource.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @resource.name = 'abcdd' * 52
    assert @resource.invalid?
    assert_equal 1, @resource.errors.count
    assert_equal error_message_from_model(@resource, :name, :too_long,
      :count => 255), @resource.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @resource.reload
    @resource.name = resources(:developer_resource).name
    assert @resource.invalid?
    assert_equal 1, @resource.errors.count
    assert_equal error_message_from_model(@resource, :name, :taken),
      @resource.errors[:name]
  end
end