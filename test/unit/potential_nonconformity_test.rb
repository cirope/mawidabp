# -*- coding: utf-8 -*-
require 'test_helper'

class PotentialNonconformityTest < ActiveSupport::TestCase
  fixtures :findings, :control_objective_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @potential_nonconformity = PotentialNonconformity.find(
      findings(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    potential_nonconformity = findings(:bcra_A4609_data_proccessing_impact_analisys_confirmed_potential_nonconformity)
    assert_kind_of PotentialNonconformity, @potential_nonconformity
    assert_equal potential_nonconformity.control_objective_item_id,
      @potential_nonconformity.control_objective_item_id
    assert_equal potential_nonconformity.review_code, @potential_nonconformity.review_code
    assert_equal potential_nonconformity.description, @potential_nonconformity.description
    assert_equal potential_nonconformity.answer, @potential_nonconformity.answer
    assert_equal potential_nonconformity.state, @potential_nonconformity.state
    assert_equal potential_nonconformity.solution_date, @potential_nonconformity.solution_date
    assert_equal potential_nonconformity.origination_date, @potential_nonconformity.origination_date
  end

  # Prueba la creación de una no conformidad potencial
  test 'create' do
    assert_difference 'PotentialNonconformity.count' do
      @potential_nonconformity = PotentialNonconformity.new(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable),
        :review_code => 'NCP20',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:being_implemented],
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

      assert @potential_nonconformity.save, @potential_nonconformity.errors.full_messages.join('; ')
      assert_equal 'NCP20', @potential_nonconformity.review_code
    end

    assert_no_difference 'PotentialNonconformity.count' do
      PotentialNonconformity.create(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item),
        :review_code => 'NCP20',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:being_implemented],
        :solution_date => 30.days.from_now.to_date,
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

  # Prueba de actualización de una no conformidad potencial
  test 'update' do
    assert @potential_nonconformity.update(
      :review_code => 'NCP20', :description => 'Updated description'),
      @potential_nonconformity.errors.full_messages.join('; ')
    @potential_nonconformity.reload
    assert_equal 'Updated description', @potential_nonconformity.description
  end

  # Prueba de eliminación de una no conformidad potencial
  test 'delete' do
    # No se puede eliminar si está en un informe definitivo
    assert_no_difference 'PotentialNonconformity.count' do
      @potential_nonconformity.destroy
    end

    @potential_nonconformity = PotentialNonconformity.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_potential_nonconformity).id)

    # Y tampoco se puede eliminar si NO está en un informe definitivo
    assert_no_difference 'PotentialNonconformity.count', -1 do
      @potential_nonconformity.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @potential_nonconformity.control_objective_item_id = nil
    @potential_nonconformity.review_code = '   '
    assert @potential_nonconformity.invalid?
    assert_equal 3, @potential_nonconformity.errors.count
    assert_equal [error_message_from_model(@potential_nonconformity,
      :control_objective_item_id, :blank)],
      @potential_nonconformity.errors[:control_objective_item_id]
    assert_equal [error_message_from_model(@potential_nonconformity, :review_code, :blank),
      error_message_from_model(@potential_nonconformity, :review_code, :invalid)].sort,
      @potential_nonconformity.errors[:review_code].sort
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    another_potential_nonconformity = PotentialNonconformity.find(findings(
        :bcra_A4609_security_management_responsible_dependency_notify_potential_nonconformity).id)
    @potential_nonconformity.review_code = another_potential_nonconformity.review_code
    assert @potential_nonconformity.invalid?
    assert_equal 1, @potential_nonconformity.errors.count
    assert_equal [error_message_from_model(@potential_nonconformity, :review_code, :taken)],
      @potential_nonconformity.errors[:review_code]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @potential_nonconformity.review_code = 'abcdd' * 52
    @potential_nonconformity.type = 'abcdd' * 52
    assert @potential_nonconformity.invalid?
    assert_equal 3, @potential_nonconformity.errors.count
    assert_equal [error_message_from_model(@potential_nonconformity, :review_code, :too_long,
      :count => 255), error_message_from_model(@potential_nonconformity, :review_code,
      :invalid)].sort, @potential_nonconformity.errors[:review_code].sort
    assert_equal [error_message_from_model(@potential_nonconformity, :type, :too_long,
      :count => 255)], @potential_nonconformity.errors[:type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @potential_nonconformity.state = Finding::STATUS.values.sort.last.next
    assert @potential_nonconformity.invalid?
    assert_equal 1, @potential_nonconformity.errors.count
    assert_equal [error_message_from_model(@potential_nonconformity, :state, :inclusion)],
      @potential_nonconformity.errors[:state]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @potential_nonconformity.control_objective_item_id = '?nil'
    assert @potential_nonconformity.invalid?
    assert_equal 1, @potential_nonconformity.errors.count
    assert_equal [error_message_from_model(@potential_nonconformity,
      :control_objective_item_id, :not_a_number)],
      @potential_nonconformity.errors[:control_objective_item_id]
  end

  test 'next code' do
    assert_equal 'NCP007', @potential_nonconformity.next_code
  end

  test 'next work paper code' do
    assert_equal 'PTNCP 00', @potential_nonconformity.last_work_paper_code
  end

  test 'review code is updated when control objective is changed' do
    potential_nonconformity = PotentialNonconformity.find(findings(
        :iso_27000_security_organization_4_2_item_editable_potential_nonconformity).id)

    assert potential_nonconformity.update(:control_objective_item_id =>
        control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable).id)
    assert_equal 'NCP004', potential_nonconformity.review_code
  end

  test 'can not change to a control objective in a final review' do
    potential_nonconformity = PotentialNonconformity.find(findings(
        :iso_27000_security_organization_4_2_item_editable_potential_nonconformity).id)

    assert_raise RuntimeError do
      potential_nonconformity.update(:control_objective_item_id =>
        control_objective_items(:iso_27000_security_policy_3_1_item).id)
    end
  end

  test 'work paper codes are updated when control objective is changed' do
    potential_nonconformity = PotentialNonconformity.find(findings(
        :iso_27000_security_organization_4_2_item_editable_potential_nonconformity).id)

    assert potential_nonconformity.update(:control_objective_item_id =>
        control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable).id)

    assert_equal 'PTNCP 01', potential_nonconformity.work_papers.first.code
  end

  test 'must be approved' do
    @potential_nonconformity = PotentialNonconformity.find(
      findings(:bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_potential_nonconformity).id
    )

    assert @potential_nonconformity.must_be_approved?
    assert @potential_nonconformity.approval_errors.blank?

    @potential_nonconformity.state = Finding::STATUS[:implemented_audited]
    @potential_nonconformity.solution_date = nil
    assert !@potential_nonconformity.must_be_approved?
    assert_equal 1, @potential_nonconformity.approval_errors.size
    assert_equal I18n.t('potential_nonconformity.errors.without_solution_date'),
      @potential_nonconformity.approval_errors.first

    @potential_nonconformity.state = Finding::STATUS[:implemented]
    @potential_nonconformity.solution_date = 2.days.from_now.to_date
    @potential_nonconformity.follow_up_date = nil
    assert !@potential_nonconformity.must_be_approved?
    assert_equal 1, @potential_nonconformity.approval_errors.size
    assert_equal I18n.t('potential_nonconformity.errors.with_solution_date'),
      @potential_nonconformity.approval_errors.first

    @potential_nonconformity.state = Finding::STATUS[:being_implemented]
    @potential_nonconformity.answer = ' '
    assert !@potential_nonconformity.must_be_approved?
    assert_equal 2, @potential_nonconformity.approval_errors.size
    assert_equal [I18n.t('potential_nonconformity.errors.without_answer'),
      I18n.t('potential_nonconformity.errors.with_solution_date')].sort,
      @potential_nonconformity.approval_errors.sort

    @potential_nonconformity.reload
    assert @potential_nonconformity.must_be_approved?
    @potential_nonconformity.state = Finding::STATUS[:notify]
    assert !@potential_nonconformity.must_be_approved?
    assert_equal 1, @potential_nonconformity.approval_errors.size
    assert_equal I18n.t('potential_nonconformity.errors.not_valid_state'),
      @potential_nonconformity.approval_errors.first

    @potential_nonconformity.reload
    @potential_nonconformity.finding_user_assignments.delete_if do |fua|
      fua.user.can_act_as_audited?
    end

    assert !@potential_nonconformity.must_be_approved?
    assert_equal 1, @potential_nonconformity.approval_errors.size
    assert_equal I18n.t('potential_nonconformity.errors.without_audited'),
      @potential_nonconformity.approval_errors.first

    @potential_nonconformity.reload
    @potential_nonconformity.finding_user_assignments.delete_if { |fua| fua.user.auditor? }
    assert !@potential_nonconformity.must_be_approved?
    assert_equal 1, @potential_nonconformity.approval_errors.size
    assert_equal I18n.t('potential_nonconformity.errors.without_auditor'),
      @potential_nonconformity.approval_errors.first

    @potential_nonconformity.reload
    @potential_nonconformity.audit_comments = '  '
    assert !@potential_nonconformity.must_be_approved?
    assert_equal 1, @potential_nonconformity.approval_errors.size
    assert_equal I18n.t('potential_nonconformity.errors.without_audit_comments'),
      @potential_nonconformity.approval_errors.first
  end

  test 'dynamic functions' do
    Finding::STATUS.each do |status, value|
      @potential_nonconformity.state = value
      assert @potential_nonconformity.send(:"#{status}?")

      Finding::STATUS.each do |k, v|
        unless k == status
          @potential_nonconformity.state = v
          assert !@potential_nonconformity.send(:"#{status}?")
        end
      end
    end
  end
end
