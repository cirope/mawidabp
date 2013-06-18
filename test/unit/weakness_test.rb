# encoding: utf-8
require 'test_helper'

# Clase para probar el modelo "Weakness"
class WeaknessTest < ActiveSupport::TestCase
  fixtures :findings, :control_objective_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @weakness = Weakness.find(
      findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    weakness = findings(:bcra_A4609_data_proccessing_impact_analisys_weakness)
    assert_kind_of Weakness, @weakness
    assert_equal weakness.control_objective_item_id,
      @weakness.control_objective_item_id
    assert_equal weakness.review_code, @weakness.review_code
    assert_equal weakness.description, @weakness.description
    assert_equal weakness.answer, @weakness.answer
    assert_equal weakness.state, @weakness.state
    assert_equal weakness.solution_date, @weakness.solution_date
    assert_equal weakness.audit_recommendations, @weakness.audit_recommendations
    assert_equal weakness.effect, @weakness.effect
    assert_equal weakness.risk, @weakness.risk
    assert_equal weakness.priority, @weakness.priority
    assert_equal weakness.follow_up_date, @weakness.follow_up_date
    assert_equal weakness.origination_date, @weakness.origination_date
  end

  # Prueba la creación de una debilidad
  test 'create' do
    assert_difference 'Weakness.count' do
      @weakness = Weakness.new(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable),
        :review_code => 'O020',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:notify],
        :solution_date => nil,
        :origination_date => 1.day.ago.to_date,
        :audit_recommendations => 'New proposed action',
        :effect => 'New effect',
        :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
        :priority => get_test_parameter(:admin_priorities).first[1],
        :follow_up_date => nil,
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

      assert @weakness.save, @weakness.errors.full_messages.join('; ')
      assert_equal 'O020', @weakness.review_code
    end

    # No se puede crear una observación de un objetivo que está en un informe
    # definitivo
    assert_no_difference 'Weakness.count' do
      Weakness.create(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item),
        :review_code => 'New review code',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:notify],
        :origination_date => 35.days.from_now.to_date,
        :solution_date => 30.days.from_now.to_date,
        :audit_recommendations => 'New proposed action',
        :effect => 'New effect',
        :risk => get_test_parameter(:admin_finding_risk_levels).first[1],
        :priority => get_test_parameter(:admin_priorities).first[1],
        :follow_up_date => 2.days.from_now.to_date,
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

  # Prueba de actualización de una debilidad
  test 'update' do
    assert @weakness.update_attributes(:description => 'Updated description'),
      @weakness.errors.full_messages.join('; ')
    @weakness.reload
    assert_equal 'Updated description', @weakness.description
  end

  # Prueba de eliminación de debilidades
  test 'delete' do
    # No se puede eliminar si está en un informe definitivo
    assert_no_difference 'Weakness.count' do
      @weakness.destroy
    end

    @weakness = Weakness.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id)

    # Y tampoco se puede eliminar si NO está en un informe definitivo
    assert_no_difference 'Weakness.count' do
      @weakness.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @weakness.control_objective_item_id = nil
    @weakness.review_code = '   '
    @weakness.state = Finding::STATUS[:notify]
    @weakness.audit_recommendations = '  '
    @weakness.risk = nil
    @weakness.priority = nil
    assert @weakness.invalid?
    assert_equal 7, @weakness.errors.count
    assert_equal [error_message_from_model(@weakness,
      :control_objective_item_id, :blank)],
      @weakness.errors[:control_objective_item_id]
    assert_equal [error_message_from_model(@weakness, :review_code, :blank),
      error_message_from_model(@weakness, :review_code, :invalid)].sort,
      @weakness.errors[:review_code].sort
    assert_equal [error_message_from_model(@weakness, :risk, :blank)],
      @weakness.errors[:risk]
    assert_equal [error_message_from_model(@weakness, :priority, :blank)],
      @weakness.errors[:priority]
    assert_equal [error_message_from_model(@weakness, :audit_recommendations, :blank)],
      @weakness.errors[:audit_recommendations]
    assert_equal [error_message_from_model(@weakness, :state, :inclusion)],
      @weakness.errors[:state]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    another_weakness = Weakness.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)
    @weakness.review_code = another_weakness.review_code
    assert @weakness.invalid?
    assert_equal 1, @weakness.errors.count
    assert_equal [error_message_from_model(@weakness, :review_code, :taken)],
      @weakness.errors[:review_code]

    # Se puede duplicar si es de otro informe
    another_weakness = Weakness.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)
    @weakness.review_code = another_weakness.review_code
    assert @weakness.valid?
  end

    # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates date attributes' do
    @weakness.correction_date = 'xxx'
    @weakness.cause_analysis_date = 'xxx'

    assert @weakness.invalid?
    assert_equal 4, @weakness.errors.count
    assert_equal error_message_from_model(@weakness, :correction_date, :invalid_date),
      @weakness.errors[:correction_date].first
    assert_equal error_message_from_model(@weakness, :cause_analysis_date, :invalid_date),
      @weakness.errors[:cause_analysis_date].first

    assert @weakness.update_attribute(:state, 0)
    @weakness.correction_date = '25/05/2013'
    @weakness.cause_analysis_date = '24/05/2013'
    @weakness.follow_up_date = '23/05/2013'
    assert @weakness.invalid?

    assert_equal 2, @weakness.errors.count
    assert_equal [I18n.t('finding.errors.correction_date_on_or_before')],
      @weakness.errors[:correction_date]
    assert_equal [I18n.t('finding.errors.cause_analysis_date_on_or_before')],
      @weakness.errors[:cause_analysis_date]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @weakness.review_code = 'abcdd' * 52
    @weakness.type = 'abcdd' * 52
    assert @weakness.invalid?
    assert_equal 3, @weakness.errors.count
    assert_equal [error_message_from_model(@weakness, :review_code, :too_long,
      :count => 255), error_message_from_model(@weakness, :review_code,
      :invalid)].sort, @weakness.errors[:review_code].sort
    assert_equal [error_message_from_model(@weakness, :type, :too_long,
      :count => 255)], @weakness.errors[:type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @weakness.state = Finding::STATUS.values.sort.last.next
    assert @weakness.invalid?
    assert_equal 1, @weakness.errors.count
    assert_equal [error_message_from_model(@weakness, :state, :inclusion)],
      @weakness.errors[:state]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @weakness.control_objective_item_id = '?nil'
    @weakness.review_code = 'BAD_PREFIX_2'
    assert @weakness.invalid?
    assert_equal 2, @weakness.errors.count
    assert_equal [error_message_from_model(@weakness,
      :control_objective_item_id, :not_a_number)],
      @weakness.errors[:control_objective_item_id]
    assert_equal [error_message_from_model(@weakness, :review_code, :invalid)],
      @weakness.errors[:review_code]
  end

  test 'next code' do
    assert_equal 'O003', @weakness.next_code
  end

  test 'next work paper code' do
    assert_equal 'PTO 04', @weakness.last_work_paper_code
  end

  test 'review code is updated when control objective is changed' do
    weakness = Weakness.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_weakness).id)

    assert weakness.update_attributes(:control_objective_item_id =>
        control_objective_items(:iso_27000_security_organization_4_2_item_editable).id)
    assert_equal 'O006', weakness.review_code
  end

  test 'can not change to a control objective in a final review' do
    weakness = Weakness.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_weakness).id)

    assert_raise RuntimeError do
      weakness.update_attributes(:control_objective_item_id =>
        control_objective_items(:iso_27000_security_policy_3_1_item).id)
    end
  end

  test 'work paper codes are updated when control objective is changed' do
    weakness = Weakness.find(findings(
        :iso_27000_security_organization_4_2_item_editable_weakness_unanswered_for_level_1_notification).id)

    assert weakness.update_attributes(:control_objective_item_id =>
        control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable).id)

    assert_equal 'PTO 06', weakness.work_papers.first.code
  end

  test 'dynamic functions' do
    Finding::STATUS.each do |status, value|
      @weakness.state = value
      assert @weakness.send(:"#{status}?")

      Finding::STATUS.each do |k, v|
        unless k == status
          @weakness.state = v
          assert !@weakness.send(:"#{status}?")
        end
      end
    end
  end

  test 'risk text' do
    risks = @weakness.get_parameter(:admin_finding_risk_levels)
    risk = risks.detect { |r| r.last == @weakness.risk }

    assert_equal risk.first, @weakness.risk_text
  end

  test 'priority text' do
    priorities = @weakness.get_parameter(:admin_priorities)
    priority = priorities.detect { |p| p.last == @weakness.priority }

    assert_equal priority.first, @weakness.priority_text
  end

  test 'must be approved' do
    assert @weakness.must_be_approved?
    assert @weakness.approval_errors.blank?
    assert @weakness.unconfirmed?

    @weakness.state = Finding::STATUS[:implemented_audited]
    @weakness.solution_date = nil
    assert !@weakness.must_be_approved?
    assert_equal 1, @weakness.approval_errors.size
    assert_equal I18n.t('weakness.errors.without_solution_date'),
      @weakness.approval_errors.first

    @weakness.state = Finding::STATUS[:implemented]
    @weakness.solution_date = 2.days.from_now.to_date
    @weakness.follow_up_date = nil
    assert !@weakness.must_be_approved?
    assert_equal 2, @weakness.approval_errors.size
    assert_equal [I18n.t('weakness.errors.with_solution_date'),
      I18n.t('weakness.errors.without_follow_up_date')].sort,
      @weakness.approval_errors.sort

    @weakness.state = Finding::STATUS[:being_implemented]
    @weakness.answer = ' '
    assert !@weakness.must_be_approved?
    assert_equal 3, @weakness.approval_errors.size
    assert_equal [I18n.t('weakness.errors.without_answer'),
      I18n.t('weakness.errors.with_solution_date'),
      I18n.t('weakness.errors.without_follow_up_date')].sort,
      @weakness.approval_errors.sort

    @weakness.reload
    assert @weakness.must_be_approved?
    @weakness.state = Finding::STATUS[:notify]
    assert !@weakness.must_be_approved?
    assert_equal 1, @weakness.approval_errors.size
    assert_equal I18n.t('weakness.errors.not_valid_state'),
      @weakness.approval_errors.first

    @weakness.reload
    @weakness.finding_user_assignments.delete_if do |fua|
      fua.user.can_act_as_audited?
    end

    assert !@weakness.must_be_approved?
    assert_equal 1, @weakness.approval_errors.size
    assert_equal I18n.t('weakness.errors.without_audited'),
      @weakness.approval_errors.first

    @weakness.reload
    @weakness.finding_user_assignments.delete_if { |fua| fua.user.auditor? }
    assert !@weakness.must_be_approved?
    assert_equal 1, @weakness.approval_errors.size
    assert_equal I18n.t('weakness.errors.without_auditor'),
      @weakness.approval_errors.first

    @weakness.reload
    @weakness.effect = ' '
    @weakness.audit_comments = '  '
    assert !@weakness.must_be_approved?
    assert_equal 2, @weakness.approval_errors.size
    assert_equal [I18n.t('weakness.errors.without_effect'),
      I18n.t('weakness.errors.without_audit_comments')].sort,
      @weakness.approval_errors.sort
  end

  test 'work papers can be added to uneditable weaknesses' do
    uneditable_weakness = Weakness.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)

    assert_no_difference 'Weakness.count' do
      assert_difference 'WorkPaper.count' do
        uneditable_weakness.update_attributes({
        :work_papers_attributes => {
            '1_new' => {
              :name => 'New post_workpaper name',
              :code => 'PTO 20',
              :number_of_pages => '10',
              :description => 'New post_workpaper description',
              :organization_id => organizations(:default_organization).id,
              :file_model_attributes => {
                :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                  'text/plain')
              }
            }
          }
        })
      end
    end
  end

  test 'work papers can not be added to uneditable and closed control objectives' do
    uneditable_weakness = Weakness.find(findings(
        :iso_27000_security_policy_3_1_item_weakness).id)
    uneditable_weakness.final = true

    assert_no_difference ['Weakness.count', 'WorkPaper.count'] do
      assert_raise(RuntimeError) do
        uneditable_weakness.update_attributes({
        :work_papers_attributes => {
            '1_new' => {
              :name => 'New post_workpaper name',
              :code => 'New post_workpaper code',
              :number_of_pages => '10',
              :description => 'New post_workpaper description',
              :organization_id => organizations(:default_organization).id,
              :file_model_attributes => {
                :file => Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH,
                  'text/plain')
              }
            }
          }
        })
      end
    end
  end

  test 'list all follow up dates and rescheduled function' do
    @weakness = Weakness.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_weakness).id)
    assert @weakness.all_follow_up_dates.blank?
    assert !@weakness.rescheduled?
    assert_not_nil @weakness.follow_up_date

    old_date = @weakness.follow_up_date.clone

    assert @weakness.update_attribute(:follow_up_date, 10.days.from_now.to_date)
    assert @weakness.reload.all_follow_up_dates(nil, true).include?(old_date)
    assert @weakness.update_attribute(:follow_up_date, 15.days.from_now.to_date)
    assert @weakness.reload.all_follow_up_dates(nil, true).include?(old_date)
    assert @weakness.reload.all_follow_up_dates(nil, true).include?(
      10.days.from_now.to_date)
    assert @weakness.rescheduled?
  end
end
