# -*- coding: utf-8 -*-
require 'test_helper'

class FortressTest < ActiveSupport::TestCase
  fixtures :findings, :control_objective_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @fortress = Fortress.find(
      findings(:bcra_A4609_security_management_responsible_dependency_fortress).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    fortress = findings(:bcra_A4609_security_management_responsible_dependency_fortress)
    assert_kind_of Fortress, @fortress
    assert_equal fortress.control_objective_item_id,
      @fortress.control_objective_item_id
    assert_equal fortress.review_code, @fortress.review_code
    assert_equal fortress.description, @fortress.description
    assert_equal fortress.origination_date, @fortress.origination_date
  end

  # Prueba la creación de una fortaleza
  test 'create' do
    assert_difference 'Fortress.count' do
      @fortress = Fortress.new(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable),
        :review_code => 'F20',
        :description => 'New description',
        :finding_user_assignments_attributes => {
          :new_1 => {
            :user_id => users(:bare_user).id, :process_owner => false
          },
          :new_2 => {
            :user_id => users(:audited_user).id, :process_owner => false
          },
          :new_3 => {
            :user_id => users(:auditor_user).id, :process_owner => false
          },
          :new_4 => {
            :user_id => users(:manager_user).id, :process_owner => false
          },
          :new_5 => {
            :user_id => users(:supervisor_user).id, :process_owner => false
          },
          :new_6 => {
            :user_id => users(:administrator_user).id, :process_owner => false
          }
        }
      )

      assert @fortress.save, @fortress.errors.full_messages.join('; ')
      assert_equal 'F20', @fortress.review_code
    end

    assert_no_difference 'Fortress.count' do
      Fortress.create(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item),
        :review_code => 'F20',
        :description => 'New description',
        :origination_date => 35.days.from_now.to_date,
        :finding_user_assignments_attributes => {
          :new_1 => {
            :user_id => users(:bare_user).id, :process_owner => false
          },
          :new_2 => {
            :user_id => users(:audited_user).id, :process_owner => true
          }
        }
      )
    end
  end

  # Prueba de actualización de una fortaleza
  test 'update' do
    assert @fortress.update_attributes(
      :review_code => 'F20', :description => 'Updated description'),
      @fortress.errors.full_messages.join('; ')
    @fortress.reload
    assert_equal 'Updated description', @fortress.description
  end

  # Prueba de eliminación de fortalezas
  test 'delete' do
    # No se puede eliminar si está en un informe definitivo
    assert_no_difference 'Fortress.count' do
      @fortress.destroy
    end

    @fortress = Fortress.find(findings(:bcra_A4609_security_management_responsible_dependency_fortress).id)

    # Y tampoco se puede eliminar si NO está en un informe definitivo
    assert_no_difference 'Fortress.count', -1 do
      @fortress.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @fortress.control_objective_item_id = nil
    @fortress.review_code = '   '
    assert @fortress.invalid?
    assert_equal 3, @fortress.errors.count
    assert_equal [error_message_from_model(@fortress,
      :control_objective_item_id, :blank)],
      @fortress.errors[:control_objective_item_id]
    assert_equal [error_message_from_model(@fortress, :review_code, :blank),
      error_message_from_model(@fortress, :review_code, :invalid)].sort,
      @fortress.errors[:review_code].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    another_fortress = Fortress.find(findings(:bcra_A4609_security_management_responsible_dependency_fortress_2).id)
    @fortress.review_code = another_fortress.review_code
    assert @fortress.invalid?
    assert_equal 1, @fortress.errors.count
    assert_equal [error_message_from_model(@fortress, :review_code, :taken)],
      @fortress.errors[:review_code]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @fortress.review_code = 'abcdd' * 52
    @fortress.type = 'abcdd' * 52
    assert @fortress.invalid?
    assert_equal 3, @fortress.errors.count
    assert_equal [error_message_from_model(@fortress, :review_code, :too_long,
      :count => 255), error_message_from_model(@fortress, :review_code,
      :invalid)].sort, @fortress.errors[:review_code].sort
    assert_equal [error_message_from_model(@fortress, :type, :too_long,
      :count => 255)], @fortress.errors[:type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @fortress.control_objective_item_id = '?nil'
    assert @fortress.invalid?
    assert_equal 1, @fortress.errors.count
    assert_equal [error_message_from_model(@fortress,
      :control_objective_item_id, :not_a_number)],
      @fortress.errors[:control_objective_item_id]
  end

  test 'next code' do
    assert_equal 'F003', @fortress.next_code
  end

  test 'next work paper code' do
    assert_equal 'PTF 04', @fortress.last_work_paper_code
  end

  test 'review code is updated when control objective is changed' do
    fortress = Fortress.find(findings(:bcra_A4609_security_management_responsible_dependency_fortress).id)

    assert fortress.update_attributes(:control_objective_item_id =>
        control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable).id)
    assert_equal 'F001', fortress.review_code
  end

  test 'can not change to a control objective in a final review' do
    fortress = Fortress.find(findings(:bcra_A4609_security_management_responsible_dependency_fortress).id)

    assert_raise RuntimeError do
      fortress.update_attributes(:control_objective_item_id =>
        control_objective_items(:iso_27000_security_policy_3_1_item).id)
    end
  end

  test 'work paper codes are updated when control objective is changed' do
    fortress = Fortress.find(findings(:bcra_A4609_security_management_responsible_dependency_fortress).id)

    assert fortress.update_attributes(:control_objective_item_id =>
        control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable).id)

    assert_equal 'PTF 04', fortress.work_papers.first.code
  end
end
