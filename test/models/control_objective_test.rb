require 'test_helper'

# Clase para probar el modelo "ControlObjective"
class ControlObjectiveTest < ActiveSupport::TestCase
  fixtures :control_objectives

  # Función para inicializar las variables utilizadas en las pruebas
  setup do
    @control_objective = ControlObjective.find(
      control_objectives(:security_policy_3_1).id)
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    assert_kind_of ControlObjective, @control_objective
    assert_equal control_objectives(:security_policy_3_1).name,
      @control_objective.name
    assert_equal control_objectives(:security_policy_3_1).relevance,
      @control_objective.relevance
    assert_equal control_objectives(:security_policy_3_1).risk,
      @control_objective.risk
    assert_equal control_objectives(:security_policy_3_1).order,
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
        :relevance => ControlObjective.relevances_values.first,
        :risk => ControlObjective.risks_values.first,
        :order => 1
      )
    end
  end

  # Prueba de actualización de una buena práctica
  test 'update' do
    assert @control_objective.update(:name => 'Updated name'),
      @control_objective.errors.full_messages.join('; ')
    @control_objective.reload
    assert_equal 'Updated name', @control_objective.name
  end

  # Prueba de eliminación de una buena práctica
  test 'destroy' do
    control_objective = control_objectives :organization_security_4_4

    control_objective.control_objective_items.clear

    assert_difference 'ControlObjective.count', -1 do
      control_objective.destroy
    end
  end

  test 'destroy related control objective' do
    # Objetivo de control con items asociados
    assert_no_difference 'ControlObjective.count' do
      @control_objective.destroy
    end

    assert_equal 1, @control_objective.errors.size
    assert_equal I18n.t('control_objective.errors.related'),
      @control_objective.errors.full_messages.join
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @control_objective.name = nil

    assert @control_objective.invalid?
    assert_error @control_objective, :name, :blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates formated attributes' do
    @control_objective.relevance = '12.3'
    @control_objective.risk = '_12'

    assert @control_objective.invalid?
    assert_error @control_objective, :relevance, :not_an_integer
    assert_error @control_objective, :risk, :not_a_number
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates that have at least one control' do
    assert @control_objective.valid?
    @control_objective.control = nil

    assert @control_objective.invalid?
    assert_error @control_objective, :control, :blank
  end

  test 'hide obsolete control objectives' do
    organization = organizations :cirope

    set_organization organization

    organization.settings.find_by(name: 'hide_obsolete_best_practices').update! value: '1'

    @control_objective.update! obsolete: true

    assert_equal ControlObjective.visible.count,  ControlObjective.count - 1

    organization.settings.find_by(name: 'hide_obsolete_best_practices').update! value: '0'

    assert_equal ControlObjective.visible.count, ControlObjective.count

    organization.settings.find_by(name: 'hide_obsolete_best_practices').destroy

    if DEFAULT_SETTINGS[:hide_obsolete_best_practices][:value] == '0'
      assert_equal ControlObjective.visible.count, ControlObjective.count
    else
      assert_equal ControlObjective.visible.count, ControlObjective.count - 1
    end
  end
end
