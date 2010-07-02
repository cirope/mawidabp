require 'test_helper'

# Clase para probar el modelo "Group"
class GroupTest < ActiveSupport::TestCase
  fixtures :groups

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @group = Group.find groups(:main_group).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Group, @group
    assert_equal groups(:main_group).name, @group.name
    assert_equal groups(:main_group).description, @group.description
  end

  # Prueba la creación de un grupo
  test 'create' do
    assert_difference 'Group.count' do
      @group = Group.create(
        :name => 'New name',
        :description => 'New description'
      )
    end
  end

  # Prueba de actualización de un grupo
  test 'update' do
    assert @group.update_attributes(:name => 'Updated name'),
      @group.errors.full_messages.join('; ')
    @group.reload
    assert_equal 'Updated name', @group.name
  end

  # Prueba de eliminación de un grupo
  test 'delete' do
    assert_difference('Group.count', -1) { @group.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @group.name = ' '
    assert @group.invalid?
    assert_equal 1, @group.errors.count
    assert_equal error_message_from_model(@group, :name, :blank),
      @group.errors.on(:name)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @group.name = 'abcdd' * 52
    assert @group.invalid?
    assert_equal 1, @group.errors.count
    assert_equal error_message_from_model(@group, :name, :too_long,
      :count => 255), @group.errors.on(:name)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @group.name = groups(:second_group).name
    assert @group.invalid?
    assert_equal 1, @group.errors.count
    assert_equal error_message_from_model(@group, :name, :taken),
      @group.errors.on(:name)
  end
end