require 'test_helper'

# Clase para probar el modelo "Control"
class ControlTest < ActiveSupport::TestCase
  fixtures :controls

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @control = Control.find controls(:iso_27000_security_policy_3_1_control_1).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Control, @control
    assert_equal controls(:iso_27000_security_policy_3_1_control_1).control,
      @control.control
    assert_equal controls(:iso_27000_security_policy_3_1_control_1).effects,
      @control.effects
    assert_equal controls(:iso_27000_security_policy_3_1_control_1).
      design_tests, @control.design_tests
    assert_equal controls(:iso_27000_security_policy_3_1_control_1).
      compliance_tests, @control.compliance_tests
    assert_equal controls(:iso_27000_security_policy_3_1_control_1).order,
      @control.order
  end

  # Prueba la creación de un control
  test 'create' do
    assert_difference 'Control.count' do
      @control = Control.create(
        :control => 'New control',
        :effects => 'New effects',
        :design_tests => 'New design tests',
        :compliance_tests => 'New compliance tests',
        :order => 1,
        :controllable => control_objectives(:iso_27000_security_policy_3_1)
      )
    end

    assert_equal 'New control', @control.reload.control
  end

  # Prueba de actualización de un control
  test 'update' do
    assert @control.update_attributes(:control => 'Updated control'),
      @control.errors.full_messages.join('; ')
    @control.reload
    assert_equal 'Updated control', @control.control
  end

  # Prueba de eliminación de controles
  test 'destroy' do
    assert_difference('Control.count', -1) { @control.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @control.control = '  '
    assert @control.invalid?
    assert_equal 1, @control.errors.count
    assert_equal error_message_from_model(@control, :control, :blank),
      @control.errors.on(:control)
  end
end