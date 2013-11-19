require 'test_helper'

# Clase para probar el modelo "Resource"
class ResourceTest < ActiveSupport::TestCase
  fixtures :resources, :resource_classes

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    set_organization

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
    assert @resource.update(:description => 'Updated resource'),
      @resource.errors.full_messages.join('; ')
    @resource.reload
    assert_equal 'Updated resource', @resource.description
  end

  # Prueba de eliminación de recursos
  test 'delete' do
    assert_difference('Resource.count', -1) do
      # TODO unscoped current_organization
      User.unscoped { @resource.destroy }
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @resource.resource_class_id = '1.2'
    @resource.cost_per_unit = '_1'

    assert @resource.invalid?
    assert_error @resource, :resource_class_id, :not_an_integer
    assert_error @resource, :cost_per_unit, :not_a_number
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @resource.name = ''

    assert @resource.invalid?
    assert_error @resource, :name, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @resource.name = 'abcdd' * 52

    assert @resource.invalid?
    assert_error @resource, :name, :too_long, count: 255
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @resource.reload
    @resource.name = resources(:developer_resource).name

    assert @resource.invalid?
    assert_error @resource, :name, :taken
  end
end
