require 'test_helper'

# Clase para probar el modelo "ProcedureControl"
class ProcedureControlTest < ActiveSupport::TestCase
  fixtures :procedure_controls, :periods, :organizations

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @procedure_control = ProcedureControl.find(
      procedure_controls(:procedure_control_iso_27001).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ProcedureControl, @procedure_control
    assert_equal procedure_controls(:procedure_control_iso_27001).period_id,
      @procedure_control.period_id
  end

  # Prueba la creación de un procedimientos de control
  test 'create' do
    assert_difference 'ProcedureControl.count' do
      ProcedureControl.create(
        :period_id => periods(:current_period).id
      )
    end
  end

  # Prueba de actualización de un procedimiento de control
  test 'update' do
    assert @procedure_control.update_attributes(
      :period_id => periods(:past_period).id),
      @procedure_control.errors.full_messages.join('; ')

    @procedure_control.reload
    assert_equal periods(:past_period).id, @procedure_control.period_id
  end

  # Prueba de eliminación de procedimientos de control
  test 'erase' do
    assert_difference 'ProcedureControl.count', -1 do
      @procedure_control.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @procedure_control.period_id = '?nil'
    assert @procedure_control.invalid?
    assert_equal 1, @procedure_control.errors.count
    assert_equal error_message_from_model(@procedure_control, :period_id,
      :not_a_number), @procedure_control.errors.on(:period_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @procedure_control.period_id = nil
    assert @procedure_control.invalid?
    assert_equal 1, @procedure_control.errors.count
    assert_equal error_message_from_model(@procedure_control, :period_id,
      :blank), @procedure_control.errors.on(:period_id)
  end
end