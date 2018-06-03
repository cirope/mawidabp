require 'test_helper'

# Clase para probar el modelo "Control"
class ControlTest < ActiveSupport::TestCase
  fixtures :controls

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @control = Control.find controls(:security_policy_3_1_control_1).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of Control, @control
    assert_equal controls(:security_policy_3_1_control_1).control,
      @control.control
    assert_equal controls(:security_policy_3_1_control_1).effects,
      @control.effects
    assert_equal controls(:security_policy_3_1_control_1).
      design_tests, @control.design_tests
    assert_equal controls(:security_policy_3_1_control_1).
      compliance_tests, @control.compliance_tests
    assert_equal controls(:security_policy_3_1_control_1).order,
      @control.order
  end

  # Prueba la creación de un control
  test 'create' do
    assert_difference 'Control.count' do
      @control = Control.create(
        control: 'New control',
        effects: 'New effects',
        design_tests: 'New design tests',
        compliance_tests: 'New compliance tests',
        sustantive_tests: 'New sustantive tests',
        order: 1,
        controllable: control_objectives(:security_policy_3_1)
      )
    end

    assert_equal 'New control', @control.reload.control
  end

  # Prueba de actualización de un control
  test 'update' do
    assert @control.update(control: 'Updated control'),
      @control.errors.full_messages.join('; ')
    @control.reload
    assert_equal 'Updated control', @control.control
  end

  # Prueba de eliminación de controles
  test 'destroy' do
    assert_difference('Control.count', -1) { @control.destroy }
  end

  test 'validates blank attributes' do
    @control.control = ' '
    @control.effects = ' '
    @control.design_tests = ' '
    @control.compliance_tests = ' '
    @control.sustantive_tests = ' '

    assert @control.valid?

    @control.validates_presence_of_control = true
    @control.validates_presence_of_effects = true
    @control.validates_presence_of_design_tests = true
    @control.validates_presence_of_compliance_tests = true
    @control.validates_presence_of_sustantive_tests = true

    assert @control.invalid?
    assert_error @control, :control, :blank
    assert_error @control, :effects, :blank
    assert_error @control, :design_tests, :blank
    assert_error @control, :compliance_tests, :blank
    assert_error @control, :sustantive_tests, :blank
  end
end
