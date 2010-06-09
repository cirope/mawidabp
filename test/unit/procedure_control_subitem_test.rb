require 'test_helper'

# Clase para probar el modelo "ProcedureControlSubitem"
class ProcedureControlSubitemTest < ActiveSupport::TestCase
  fixtures :procedure_control_subitems, :procedure_control_items,
    :control_objectives

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @procedure_control_subitem = ProcedureControlSubitem.find(
      procedure_control_subitems(:procedure_control_subitem_iso_27001_1_1).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_procedure_control_subitem =
      procedure_control_subitems(:procedure_control_subitem_iso_27001_1_1)
    assert_kind_of ProcedureControlSubitem, @procedure_control_subitem
    assert_equal fixture_procedure_control_subitem.risk,
      @procedure_control_subitem.risk
    assert_equal fixture_procedure_control_subitem.order,
      @procedure_control_subitem.order
  end

  # Prueba la creación de un subitem del procedimiento de control
  test 'create with custom control objective text' do
    assert_difference ['ProcedureControlSubitem.count', 'Control.count'] do
      procedure_control_subitem = ProcedureControlSubitem.create(
        :procedure_control_item_id =>
          procedure_control_items(:procedure_control_item_iso_27001_2).id,
        :control_objective_id =>
          control_objectives(:iso_27000_security_policy_3_1).id,
        :control_objective_text => 'New CO text',
        :controls_attributes => {
          :new_1 => {
            :control => 'New control',
            :design_tests => 'New design tests',
            :compliance_tests => 'New compliance tests',
            :effects => 'New effects'
          }
        },
        :risk =>
          get_test_parameter(:admin_control_objective_risk_levels).first[1],
        :order => 1
      )

      assert_equal 'New CO text',
        procedure_control_subitem.control_objective_text
    end
  end

  # Prueba la creación de un subitem del procedimiento de control
  test 'create with defaul control objective text' do
    assert_difference ['ProcedureControlSubitem.count', 'Control.count'] do
      procedure_control_subitem = ProcedureControlSubitem.create(
        :procedure_control_item_id =>
          procedure_control_items(:procedure_control_item_iso_27001_2).id,
        :control_objective_id =>
          control_objectives(:iso_27000_security_policy_3_1).id,
        :controls_attributes => {
          :new_1 => {
            :control => 'Updated control',
            :design_tests => 'Updated design tests',
            :compliance_tests => 'Updated compliance tests',
            :effects => 'Updated effects'
          }
        },
        :risk =>
          get_test_parameter(:admin_control_objective_risk_levels).first[1],
        :order => 1
      )

      assert_equal control_objectives(:iso_27000_security_policy_3_1).name,
        procedure_control_subitem.reload.control_objective_text
      assert_equal 'Updated control',
        procedure_control_subitem.controls.last.control
    end
  end

  # Prueba de actualización de un subitem del procedimiento de control
  test 'update' do
    assert @procedure_control_subitem.update_attributes(
      :control_objective_text => 'Updated control objective text'),
      @procedure_control_subitem.errors.full_messages.join('; ')

    @procedure_control_subitem.reload
    assert_equal 'Updated control objective text',
      @procedure_control_subitem.control_objective_text
  end

  # Prueba de eliminación de subitems del procedimiento de control
  test 'delete' do
    assert_difference 'ProcedureControlSubitem.count', -1 do
      @procedure_control_subitem.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @procedure_control_subitem.procedure_control_item_id = '?123'
    @procedure_control_subitem.control_objective_id = '?123'
    @procedure_control_subitem.risk = '?123'
    @procedure_control_subitem.order = '?123'
    assert @procedure_control_subitem.invalid?
    assert_equal 4, @procedure_control_subitem.errors.count
    assert_equal error_message_from_model(@procedure_control_subitem, 
      :procedure_control_item_id, :not_a_number),
      @procedure_control_subitem.errors.on(:procedure_control_item_id)
    assert_equal error_message_from_model(@procedure_control_subitem,
      :control_objective_id, :not_a_number),
      @procedure_control_subitem.errors.on(:control_objective_id)
    assert_equal error_message_from_model(@procedure_control_subitem, :risk,
      :not_a_number), @procedure_control_subitem.errors.on(:risk)
    assert_equal error_message_from_model(@procedure_control_subitem, :order,
      :not_a_number), @procedure_control_subitem.errors.on(:order)
  end
  
  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @procedure_control_subitem.control_objective_text = ' '
    @procedure_control_subitem.control_objective_id = nil
    @procedure_control_subitem.risk = ' '
    @procedure_control_subitem.order = nil
    assert @procedure_control_subitem.invalid?
    assert_equal 4, @procedure_control_subitem.errors.count
    assert_equal error_message_from_model(@procedure_control_subitem,
      :control_objective_text, :blank),
      @procedure_control_subitem.errors.on(:control_objective_text)
    assert_equal error_message_from_model(@procedure_control_subitem,
      :control_objective_id, :blank),
      @procedure_control_subitem.errors.on(:control_objective_id)
    assert_equal error_message_from_model(@procedure_control_subitem, :risk,
      :blank), @procedure_control_subitem.errors.on(:risk)
    assert_equal error_message_from_model(@procedure_control_subitem, :order,
      :blank), @procedure_control_subitem.errors.on(:order)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @procedure_control_subitem.control_objective_id = 
      procedure_control_subitems(:procedure_control_subitem_iso_27001_1_2).
      control_objective_id
    assert @procedure_control_subitem.invalid?
    assert_equal 1, @procedure_control_subitem.errors.count
    assert_equal error_message_from_model(@procedure_control_subitem,
      :control_objective_id, :taken), @procedure_control_subitem.errors.on(
      :control_objective_id)
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates that have at least one control' do
    assert @procedure_control_subitem.valid?
    @procedure_control_subitem.control_ids = []
    assert @procedure_control_subitem.invalid?
    assert_equal 1, @procedure_control_subitem.errors.count
    assert_equal error_message_from_model(@procedure_control_subitem, :controls,
      :blank), @procedure_control_subitem.errors.on(:controls)
  end
end