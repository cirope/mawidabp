require 'test_helper'

# Clase para probar el modelo "ProcedureControlItem"
class ProcedureControlItemTest < ActiveSupport::TestCase
  fixtures :procedure_control_items, :procedure_controls, :process_controls

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @procedure_control_item = ProcedureControlItem.find(
      procedure_control_items(:procedure_control_item_iso_27001_1).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_procedure_control_item =
      procedure_control_items(:procedure_control_item_iso_27001_1)
    assert_kind_of ProcedureControlItem, @procedure_control_item
    assert_equal fixture_procedure_control_item.aproach,
      @procedure_control_item.aproach
    assert_equal fixture_procedure_control_item.frequency,
      @procedure_control_item.frequency
    assert_equal fixture_procedure_control_item.order,
      @procedure_control_item.order
  end

  # Prueba la creación de un items de procedimientos de control
  test 'create' do
    assert_difference 'ProcedureControlItem.count' do
      ProcedureControlItem.create(
        :procedure_control_id =>
          procedure_controls(:procedure_control_iso_27001).id,
        :process_control_id =>
          process_controls(:iso_27000_assets_control).id,
        :aproach => 1,
        :frequency => 1,
        :order => 1
      )
    end
  end

  # Prueba de actualización de un ítem de procedimiento de control
  test 'update' do
    assert @procedure_control_item.update_attributes(:order => 10),
      @procedure_control_item.errors.full_messages.join('; ')

    @procedure_control_item.reload
    assert_equal 10, @procedure_control_item.order
  end

  # Prueba de eliminación de items de procedimientos de control
  test 'delete' do
    assert_difference 'ProcedureControlItem.count', -1 do
      @procedure_control_item.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @procedure_control_item.process_control_id = '?123'
    @procedure_control_item.procedure_control_id = '?123'
    @procedure_control_item.aproach = '?123'
    @procedure_control_item.frequency = '?123'
    @procedure_control_item.order = '?123'
    assert @procedure_control_item.invalid?
    assert_equal 5, @procedure_control_item.errors.count
    assert_equal [error_message_from_model(@procedure_control_item,
      :process_control_id, :not_a_number)],
      @procedure_control_item.errors[:process_control_id]
    assert_equal [error_message_from_model(@procedure_control_item,
      :procedure_control_id, :not_a_number)],
      @procedure_control_item.errors[:procedure_control_id]
    assert_equal [error_message_from_model(@procedure_control_item, :aproach,
      :not_a_number)], @procedure_control_item.errors[:aproach]
    assert_equal [error_message_from_model(@procedure_control_item, :frequency,
      :not_a_number)], @procedure_control_item.errors[:frequency]
    assert_equal [error_message_from_model(@procedure_control_item, :order,
      :not_a_number)], @procedure_control_item.errors[:order]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @procedure_control_item.process_control_id = nil
    @procedure_control_item.aproach = ' '
    @procedure_control_item.frequency = ''
    @procedure_control_item.order = nil
    assert @procedure_control_item.invalid?
    assert_equal 4, @procedure_control_item.errors.count
    assert_equal [error_message_from_model(@procedure_control_item,
      :process_control_id, :blank)],
      @procedure_control_item.errors[:process_control_id]
    assert_equal [error_message_from_model(@procedure_control_item, :aproach,
      :blank)], @procedure_control_item.errors[:aproach]
    assert_equal [error_message_from_model(@procedure_control_item, :frequency,
      :blank)], @procedure_control_item.errors[:frequency]
    assert_equal [error_message_from_model(@procedure_control_item, :order,
      :blank)], @procedure_control_item.errors[:order]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @procedure_control_item.process_control_id =
      procedure_control_items(:procedure_control_item_iso_27001_2).
      process_control_id
    assert @procedure_control_item.invalid?
    assert_equal 1, @procedure_control_item.errors.count
    assert_equal [error_message_from_model(@procedure_control_item,
      :process_control_id, :taken)], @procedure_control_item.errors[
      :process_control_id]
  end
end