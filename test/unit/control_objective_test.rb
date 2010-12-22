require 'test_helper'

# Clase para probar el modelo "ControlObjective"
class ControlObjectiveTest < ActiveSupport::TestCase
  fixtures :control_objectives
  
  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @control_objective = ControlObjective.find(
      control_objectives(:iso_27000_security_policy_3_1).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ControlObjective, @control_objective
    assert_equal control_objectives(:iso_27000_security_policy_3_1).name,
      @control_objective.name
    assert_equal control_objectives(:iso_27000_security_policy_3_1).relevance,
      @control_objective.relevance
    assert_equal control_objectives(:iso_27000_security_policy_3_1).risk,
      @control_objective.risk
    assert_equal control_objectives(:iso_27000_security_policy_3_1).order,
      @control_objective.order
  end

  # Prueba la creación de una buena práctica
  test 'create' do
    assert_difference ['ControlObjective.count', 'Control.count'] do
      @control_objective = ControlObjective.create(
        :name => 'New name',
        :control_attributes => {
          :control => 'New control',
          :effects => 'New effects',
          :design_tests => 'New design tests',
          :compliance_tests => 'New compliance tests',
          :sustantive_tests => 'New sustantive tests'
        },
        :relevance =>
          get_test_parameter(:admin_control_objective_importances).first[1],
        :risk =>
          get_test_parameter(:admin_control_objective_risk_levels).first[1],
        :order => 1
      )
    end
  end

  # Prueba de actualización de una buena práctica
  test 'update' do
    assert @control_objective.update_attributes(:name => 'Updated name'),
      @control_objective.errors.full_messages.join('; ')
    @control_objective.reload
    assert_equal 'Updated name', @control_objective.name
  end

  # Prueba de eliminación de una buena práctica
  test 'destroy' do
    # Objetivo de control sin items asociados
    assert_difference 'ControlObjective.count', -1 do
      ControlObjective.find(control_objectives(
          :iso_27000_security_organization_4_3).id).destroy
    end
  end

  test 'destroy related control objective' do
    # Objetivo de control con items asociados
    assert_no_difference 'ControlObjective.count' do
      @control_objective.destroy
    end

    assert_equal 1, @control_objective.errors.size
    assert_equal I18n.t(:'control_objective.errors.related'),
      @control_objective.errors.full_messages.join
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @control_objective.name = nil
    assert @control_objective.invalid?
    assert_equal 1, @control_objective.errors.count
    assert_equal [error_message_from_model(@control_objective, :name, :blank)],
      @control_objective.errors[:name]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @control_objective.relevance = '12.3'
    @control_objective.risk = '_12'
    assert @control_objective.invalid?
    assert_equal 2, @control_objective.errors.count
    assert_equal [error_message_from_model(@control_objective, :relevance,
      :not_an_integer)], @control_objective.errors[:relevance]
    assert_equal [error_message_from_model(@control_objective, :risk,
      :not_a_number)], @control_objective.errors[:risk]
  end

  test 'validates duplicated attributes' do
    @control_objective.name =
      control_objectives(:iso_27000_security_organization_4_1).name
    assert @control_objective.invalid?
    assert_equal 1, @control_objective.errors.count
    assert_equal [error_message_from_model(@control_objective, :name, :taken)],
      @control_objective.errors[:name]

    # Nombres iguales pero distintos procesos de negocio
    @control_objective.name =
      control_objectives(:bcra_A4609_data_proccessing_impact_analisys).name
    assert @control_objective.valid?,
      @control_objective.errors.full_messages.join('; ')
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates that have at least one control' do
    assert @control_objective.valid?
    @control_objective.control = nil
    assert @control_objective.invalid?
    assert_equal 1, @control_objective.errors.count
    assert_equal [error_message_from_model(@control_objective, :control,
      :blank)], @control_objective.errors[:control]
  end
end