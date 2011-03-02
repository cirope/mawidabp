require 'test_helper'

# Clase para probar el modelo "Oportunity"
class OportunityTest < ActiveSupport::TestCase
  fixtures :findings, :control_objective_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @oportunity = Oportunity.find(
      findings(:bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    oportunity = findings(:bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity)
    assert_kind_of Oportunity, @oportunity
    assert_equal oportunity.control_objective_item_id,
      @oportunity.control_objective_item_id
    assert_equal oportunity.review_code, @oportunity.review_code
    assert_equal oportunity.description, @oportunity.description
    assert_equal oportunity.answer, @oportunity.answer
    assert_equal oportunity.state, @oportunity.state
    assert_equal oportunity.solution_date, @oportunity.solution_date
    assert_equal oportunity.origination_date, @oportunity.origination_date
  end

  # Prueba la creación de una oportunidad
  test 'create' do
    assert_difference 'Oportunity.count' do
      @oportunity = Oportunity.new(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable),
        :review_code => 'OM20',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:being_implemented],
        :finding_user_assignments_attributes => {
          :new_1 => { :user_id => users(:bare_user).id },
          :new_2 => { :user_id => users(:audited_user).id },
          :new_3 => { :user_id => users(:auditor_user).id },
          :new_4 => { :user_id => users(:manager_user).id },
          :new_5 => { :user_id => users(:supervisor_user).id },
          :new_6 => { :user_id => users(:administrator_user).id }
        }
      )

      assert @oportunity.save, @oportunity.errors.full_messages.join('; ')
      assert_equal 'OM20', @oportunity.review_code
    end

    assert_no_difference 'Oportunity.count' do
      Oportunity.create(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item),
        :review_code => 'OM20',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:being_implemented],
        :solution_date => 30.days.from_now.to_date,
        :origination_date => 35.days.from_now.to_date,
        :finding_user_assignments_attributes => {
          :new_1 => { :user_id => users(:bare_user).id },
          :new_2 => { :user_id => users(:audited_user).id }
        }
      )
    end
  end

  # Prueba de actualización de una oportunidad
  test 'update' do
    assert @oportunity.update_attributes(
      :review_code => 'OM20', :description => 'Updated description'),
      @oportunity.errors.full_messages.join('; ')
    @oportunity.reload
    assert_equal 'Updated description', @oportunity.description
  end

  # Prueba de eliminación de oportunidades
  test 'delete' do
    # No se puede eliminar si está en un informe definitivo
    assert_no_difference 'Oportunity.count', -1 do
      @oportunity.destroy
    end

    @oportunity = Oportunity.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_oportunity).id)

    assert_difference 'Oportunity.count', -1 do
      @oportunity.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @oportunity.control_objective_item_id = nil
    @oportunity.review_code = '   '
    assert @oportunity.invalid?
    assert_equal 3, @oportunity.errors.count
    assert_equal [error_message_from_model(@oportunity,
      :control_objective_item_id, :blank)],
      @oportunity.errors[:control_objective_item_id]
    assert_equal [error_message_from_model(@oportunity, :review_code, :blank),
      error_message_from_model(@oportunity, :review_code, :invalid)].sort,
      @oportunity.errors[:review_code].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    another_oportunity = Oportunity.find(findings(
        :bcra_A4609_security_management_responsible_dependency_notify_oportunity).id)
    @oportunity.review_code = another_oportunity.review_code
    assert @oportunity.invalid?
    assert_equal 1, @oportunity.errors.count
    assert_equal [error_message_from_model(@oportunity, :review_code, :taken)],
      @oportunity.errors[:review_code]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @oportunity.review_code = 'abcdd' * 52
    @oportunity.type = 'abcdd' * 52
    assert @oportunity.invalid?
    assert_equal 3, @oportunity.errors.count
    assert_equal [error_message_from_model(@oportunity, :review_code, :too_long,
      :count => 255), error_message_from_model(@oportunity, :review_code,
      :invalid)].sort, @oportunity.errors[:review_code].sort
    assert_equal [error_message_from_model(@oportunity, :type, :too_long,
      :count => 255)], @oportunity.errors[:type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @oportunity.state = Finding::STATUS.values.sort.last.next
    assert @oportunity.invalid?
    assert_equal 1, @oportunity.errors.count
    assert_equal [error_message_from_model(@oportunity, :state, :inclusion)],
      @oportunity.errors[:state]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @oportunity.control_objective_item_id = '?nil'
    assert @oportunity.invalid?
    assert_equal 1, @oportunity.errors.count
    assert_equal [error_message_from_model(@oportunity,
      :control_objective_item_id, :not_a_number)],
      @oportunity.errors[:control_objective_item_id]
  end

  test 'next code' do
    assert_equal 'OM004', @oportunity.next_code
  end

  test 'next work paper code' do
    assert_equal 'PTOM 00', @oportunity.last_work_paper_code
  end

  test 'review code is updated when control objective is changed' do
    oportunity = Oportunity.find(findings(
        :iso_27000_security_organization_4_2_item_editable_oportunity).id)

    assert oportunity.update_attributes(:control_objective_item_id =>
        control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable).id)
    assert_equal 'OM004', oportunity.review_code
  end

  test 'work paper codes are updated when control objective is changed' do
    oportunity = Oportunity.find(findings(
        :iso_27000_security_organization_4_2_item_editable_oportunity).id)

    assert oportunity.update_attributes(:control_objective_item_id =>
        control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable).id)
    assert_equal 'PTOM 04', oportunity.work_papers.first.code
  end

  test 'dynamic functions' do
    Finding::STATUS.each do |status, value|
      @oportunity.state = value
      assert @oportunity.send(:"#{status}?")

      Finding::STATUS.each do |k, v|
        unless k == status
          @oportunity.state = v
          assert !@oportunity.send(:"#{status}?")
        end
      end
    end
  end
end