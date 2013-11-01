require 'test_helper'

# Clase para probar el modelo "HelpItem"
class HelpItemTest < ActiveSupport::TestCase
  fixtures :help_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @help_item = HelpItem.find help_items(:help_item_1_es).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of HelpItem, @help_item
    assert_equal help_items(:help_item_1_es).name, @help_item.name
    assert_equal help_items(:help_item_1_es).description, @help_item.description
    assert_equal help_items(:help_item_1_es).order_number,
      @help_item.order_number
    assert_equal help_items(:help_item_1_es).parent_id, @help_item.parent_id
    assert_equal help_items(:help_item_1_es).help_content_id,
      @help_item.help_content_id
  end

  # Prueba la creación de un item de ayuda
  test 'create' do
    assert_difference 'HelpItem.count' do
      HelpItem.create(
        :name => 'New name',
        :description => 'New description',
        :order_number => 1,
        :parent => @help_item,
        :help_content => nil
      )
    end
  end

  # Prueba de actualización de un item de ayuda
  test 'update' do
    assert @help_item.update(:name => 'Updated name'),
      @help_item.errors.full_messages.join('; ')
    @help_item.reload
    assert_equal 'Updated name', @help_item.name
  end

  # Prueba de eliminación de items de ayuda
  test 'delete' do
    assert_difference('HelpItem.count', -2) { @help_item.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @help_item.name = nil
    @help_item.description = '  '
    @help_item.order_number = nil

    assert @help_item.invalid?
    assert_error @help_item, :name, :blank
    assert_error @help_item, :description, :blank
    assert_error @help_item, :order_number, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @help_item.order_number = '?123'

    assert @help_item.invalid?
    assert_error @help_item, :order_number, :not_a_number
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @help_item.name = 'abcde' * 52

    assert @help_item.invalid?
    assert_error @help_item, :name, :too_long, count: 255
  end
end
