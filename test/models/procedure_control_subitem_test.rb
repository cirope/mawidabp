require 'test_helper'

# Clase para probar el modelo "ProcedureControlSubitem"
class ProcedureControlSubitemTest < ActiveSupport::TestCase
  fixtures :procedure_control_subitems, :procedure_control_items,
    :control_objectives

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    set_organization

    @procedure_control_subitem = ProcedureControlSubitem.find(
      procedure_control_subitems(:procedure_control_subitem_iso_27001_1_1).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fixture_procedure_control_subitem =
      procedure_control_subitems(:procedure_control_subitem_iso_27001_1_1)
    assert_kind_of ProcedureControlSubitem, @procedure_control_subitem
    assert_equal fixture_procedure_control_subitem.relevance,
      @procedure_control_subitem.relevance
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
        :control_attributes => {
          :control => 'New control',
          :design_tests => 'New design tests',
          :compliance_tests => 'New compliance tests',
          :sustantive_tests => 'New sustantive tests',
          :effects => 'New effects'
        },
        :relevance => ProcedureControlSubitem.relevances_values.first,
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
        :control_attributes => {
          :control => 'Updated control',
          :design_tests => 'Updated design tests',
          :compliance_tests => 'Updated compliance tests',
          :sustantive_tests => 'Updated sustantive tests',
          :effects => 'Updated effects'
        },
        :relevance => ProcedureControlSubitem.relevances_values.first,
        :order => 1
      )

      assert_equal control_objectives(:iso_27000_security_policy_3_1).name,
        procedure_control_subitem.reload.control_objective_text
      assert_equal 'Updated control',
        procedure_control_subitem.control.control
    end
  end

  # Prueba de actualización de un subitem del procedimiento de control
  test 'update' do
    assert @procedure_control_subitem.update(
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
    @procedure_control_subitem.relevance = '?123'
    @procedure_control_subitem.order = '?123'

    assert @procedure_control_subitem.invalid?
    assert_error @procedure_control_subitem, :procedure_control_item_id, :not_a_number
    assert_error @procedure_control_subitem, :control_objective_id, :not_a_number
    assert_error @procedure_control_subitem, :relevance, :not_a_number
    assert_error @procedure_control_subitem, :order, :not_a_number
  end
  
  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @procedure_control_subitem.control_objective_text = ' '
    @procedure_control_subitem.control_objective_id = nil
    @procedure_control_subitem.relevance = ' '
    @procedure_control_subitem.order = nil

    assert @procedure_control_subitem.invalid?
    assert_error @procedure_control_subitem, :control_objective_text, :blank
    assert_error @procedure_control_subitem, :control_objective_id, :blank
    assert_error @procedure_control_subitem, :relevance, :blank
    assert_error @procedure_control_subitem, :order, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    @procedure_control_subitem.control_objective_id = 
      procedure_control_subitems(:procedure_control_subitem_iso_27001_1_2).
      control_objective_id

    assert @procedure_control_subitem.invalid?
    assert_error @procedure_control_subitem, :control_objective_id, :taken
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates that have at least one control' do
    assert @procedure_control_subitem.valid?
    @procedure_control_subitem.control = nil

    assert @procedure_control_subitem.invalid?
    assert_error @procedure_control_subitem, :control, :blank
  end
end
