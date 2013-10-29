require 'test_helper'

class NonconformityTest < ActiveSupport::TestCase
  fixtures :findings, :control_objective_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @nonconformity = Nonconformity.find(
      findings(:bcra_A4609_data_proccessing_impact_analisys_nonconformity).id)
    GlobalModelConfig.current_organization_id =
      organizations(:default_organization).id
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    nonconformity = findings(:bcra_A4609_data_proccessing_impact_analisys_nonconformity)
    assert_kind_of Nonconformity, @nonconformity
    assert_equal nonconformity.control_objective_item_id,
      @nonconformity.control_objective_item_id
    assert_equal nonconformity.review_code, @nonconformity.review_code
    assert_equal nonconformity.description, @nonconformity.description
    assert_equal nonconformity.answer, @nonconformity.answer
    assert_equal nonconformity.state, @nonconformity.state
    assert_equal nonconformity.solution_date, @nonconformity.solution_date
    assert_equal nonconformity.audit_recommendations, @nonconformity.audit_recommendations
    assert_equal nonconformity.effect, @nonconformity.effect
    assert_equal nonconformity.risk, @nonconformity.risk
    assert_equal nonconformity.priority, @nonconformity.priority
    assert_equal nonconformity.follow_up_date, @nonconformity.follow_up_date
    assert_equal nonconformity.origination_date, @nonconformity.origination_date
  end

  # Prueba la creación de una no conformidad
  test 'create' do
    assert_difference 'Nonconformity.count' do
      @nonconformity = Nonconformity.new(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable),
        :review_code => 'NC020',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:notify],
        :solution_date => nil,
        :origination_date => 1.day.ago.to_date,
        :audit_recommendations => 'New proposed action',
        :effect => 'New effect',
        :risk => Nonconformity.risks_values.first,
        :priority => Nonconformity.priorities_values.first,
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

      assert @nonconformity.save, @nonconformity.errors.full_messages.join('; ')
      assert_equal 'NC020', @nonconformity.review_code
    end

    # No se puede crear una no conformidad de un objetivo que está en un informe
    # definitivo
    assert_no_difference 'Nonconformity.count' do
      Nonconformity.create(
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
        :risk => Nonconformity.risks_values.first,
        :priority => Nonconformity.priorities_values.first,
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

  # Prueba de actualización de una no conformidad
  test 'update' do
    assert @nonconformity.update(:description => 'Updated description'),
      @nonconformity.errors.full_messages.join('; ')
    @nonconformity.reload
    assert_equal 'Updated description', @nonconformity.description
  end

  # Prueba de eliminación de no conformidades
  test 'delete' do
    # No se puede eliminar si está en un informe definitivo
    assert_no_difference 'Nonconformity.count' do
      @nonconformity.destroy
    end

    @nonconformity = Nonconformity.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_nonconformity).id)

    # Y tampoco se puede eliminar si NO está en un informe definitivo
    assert_no_difference 'Nonconformity.count' do
      @nonconformity.destroy
    end
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @nonconformity.control_objective_item_id = nil
    @nonconformity.review_code = '   '
    @nonconformity.state = Finding::STATUS[:notify]
    @nonconformity.audit_recommendations = '  '
    @nonconformity.risk = nil
    @nonconformity.priority = nil
    assert @nonconformity.invalid?
    assert_equal 7, @nonconformity.errors.count
    assert_equal [error_message_from_model(@nonconformity,
      :control_objective_item_id, :blank)],
      @nonconformity.errors[:control_objective_item_id]
    assert_equal [error_message_from_model(@nonconformity, :review_code, :blank),
      error_message_from_model(@nonconformity, :review_code, :invalid)].sort,
      @nonconformity.errors[:review_code].sort
    assert_equal [error_message_from_model(@nonconformity, :risk, :blank)],
      @nonconformity.errors[:risk]
    assert_equal [error_message_from_model(@nonconformity, :priority, :blank)],
      @nonconformity.errors[:priority]
    assert_equal [error_message_from_model(@nonconformity, :audit_recommendations, :blank)],
      @nonconformity.errors[:audit_recommendations]
    assert_equal [error_message_from_model(@nonconformity, :state, :inclusion)],
      @nonconformity.errors[:state]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    another_nonconformity = Nonconformity.find(findings(
        :bcra_A4609_security_management_responsible_dependency_nonconformity_being_implemented).id)
    @nonconformity.review_code = another_nonconformity.review_code
    assert @nonconformity.invalid?
    assert_equal 1, @nonconformity.errors.count
    assert_equal [error_message_from_model(@nonconformity, :review_code, :taken)],
      @nonconformity.errors[:review_code]

    # Se puede duplicar si es de otro informe
    another_nonconformity = Nonconformity.find(findings(
        :iso_27000_security_policy_3_1_item_nonconformity_unconfirmed_for_notification).id)
    @nonconformity.review_code = another_nonconformity.review_code
    assert @nonconformity.valid?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @nonconformity.review_code = 'abcdd' * 52
    @nonconformity.type = 'abcdd' * 52
    assert @nonconformity.invalid?
    assert_equal 3, @nonconformity.errors.count
    assert_equal [error_message_from_model(@nonconformity, :review_code, :too_long,
      :count => 255), error_message_from_model(@nonconformity, :review_code,
      :invalid)].sort, @nonconformity.errors[:review_code].sort
    assert_equal [error_message_from_model(@nonconformity, :type, :too_long,
      :count => 255)], @nonconformity.errors[:type]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    @nonconformity.state = Finding::STATUS.values.sort.last.next
    assert @nonconformity.invalid?
    assert_equal 1, @nonconformity.errors.count
    assert_equal [error_message_from_model(@nonconformity, :state, :inclusion)],
      @nonconformity.errors[:state]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates date attributes' do
    @nonconformity.correction_date = 'xxx'
    @nonconformity.cause_analysis_date = 'xxx'

    assert @nonconformity.invalid?
    assert_equal 4, @nonconformity.errors.count
    assert_equal error_message_from_model(@nonconformity, :correction_date, :invalid_date),
      @nonconformity.errors[:correction_date].first
    assert_equal error_message_from_model(@nonconformity, :cause_analysis_date, :invalid_date),
      @nonconformity.errors[:cause_analysis_date].first

    assert @nonconformity.update_attribute(:state, 0)
    @nonconformity.correction_date = '25/05/2013'
    @nonconformity.cause_analysis_date = '24/05/2013'
    @nonconformity.follow_up_date = '23/05/2013'
    assert @nonconformity.invalid?

    assert_equal 2, @nonconformity.errors.count
    assert_equal [I18n.t('finding.errors.correction_date_on_or_before')],
      @nonconformity.errors[:correction_date]
    assert_equal [I18n.t('finding.errors.cause_analysis_date_on_or_before')],
      @nonconformity.errors[:cause_analysis_date]
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @nonconformity.control_objective_item_id = '?nil'
    @nonconformity.review_code = 'BAD_PREFIX_2'
    assert @nonconformity.invalid?
    assert_equal 2, @nonconformity.errors.count
    assert_equal [error_message_from_model(@nonconformity,
      :control_objective_item_id, :not_a_number)],
      @nonconformity.errors[:control_objective_item_id]
    assert_equal [error_message_from_model(@nonconformity, :review_code, :invalid)],
      @nonconformity.errors[:review_code]
  end

  test 'next code' do
    assert_equal 'NC003', @nonconformity.next_code
  end

  test 'next work paper code' do
    assert_equal 'PTNC 01', @nonconformity.last_work_paper_code
  end

  test 'review code is updated when control objective is changed' do
    nonconformity = Nonconformity.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_nonconformity).id)

    assert nonconformity.update(:control_objective_item_id =>
        control_objective_items(:iso_27000_security_organization_4_2_item_editable).id)
    assert_equal 'NC006', nonconformity.review_code
  end

  test 'can not change to a control objective in a final review' do
    nonconformity = Nonconformity.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_nonconformity).id)

    assert_raise RuntimeError do
      nonconformity.update(:control_objective_item_id =>
        control_objective_items(:iso_27000_security_policy_3_1_item).id)
    end
  end

  test 'work paper codes are updated when control objective is changed' do
    nonconformity = Nonconformity.find(findings(
        :iso_27000_security_organization_4_2_item_editable_nonconformity_unanswered_for_level_1_notification).id)

    assert nonconformity.update(:control_objective_item_id =>
        control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable).id)

    assert_equal 'PTNC 01', nonconformity.work_papers.first.code
  end

  test 'dynamic functions' do
    Finding::STATUS.each do |status, value|
      @nonconformity.state = value
      assert @nonconformity.send(:"#{status}?")

      Finding::STATUS.each do |k, v|
        unless k == status
          @nonconformity.state = v
          assert !@nonconformity.send(:"#{status}?")
        end
      end
    end
  end

  test 'risk text' do
    risk = Nonconformity.risks.detect { |r| r.last == @nonconformity.risk }

    assert_equal I18n.t("risk_types.#{risk.first}"), @nonconformity.risk_text
  end

  test 'priority text' do
    priority = Nonconformity.priorities.detect { |p| p.last == @nonconformity.priority }

    assert_equal I18n.t("priority_types.#{priority.first}"), @nonconformity.priority_text
  end

  test 'must be approved' do
    assert @nonconformity.must_be_approved?
    assert @nonconformity.approval_errors.blank?
    assert @nonconformity.unconfirmed?

    @nonconformity.state = Finding::STATUS[:implemented_audited]
    @nonconformity.solution_date = nil
    assert !@nonconformity.must_be_approved?
    assert_equal 1, @nonconformity.approval_errors.size
    assert_equal I18n.t('nonconformity.errors.without_solution_date'),
      @nonconformity.approval_errors.first

    @nonconformity.state = Finding::STATUS[:implemented]
    @nonconformity.solution_date = 2.days.from_now.to_date
    @nonconformity.follow_up_date = nil
    assert !@nonconformity.must_be_approved?
    assert_equal 2, @nonconformity.approval_errors.size
    assert_equal [I18n.t('nonconformity.errors.with_solution_date'),
      I18n.t('nonconformity.errors.without_follow_up_date')].sort,
      @nonconformity.approval_errors.sort

    @nonconformity.state = Finding::STATUS[:being_implemented]
    @nonconformity.answer = ' '
    assert !@nonconformity.must_be_approved?
    assert_equal 3, @nonconformity.approval_errors.size
    assert_equal [I18n.t('nonconformity.errors.without_answer'),
      I18n.t('nonconformity.errors.with_solution_date'),
      I18n.t('nonconformity.errors.without_follow_up_date')].sort,
      @nonconformity.approval_errors.sort

    @nonconformity.reload
    assert @nonconformity.must_be_approved?
    @nonconformity.state = Finding::STATUS[:notify]
    assert !@nonconformity.must_be_approved?
    assert_equal 1, @nonconformity.approval_errors.size
    assert_equal I18n.t('nonconformity.errors.not_valid_state'),
      @nonconformity.approval_errors.first

    @nonconformity.reload
    @nonconformity.finding_user_assignments =
      @nonconformity.finding_user_assignments.reject do |fua|
        fua.user.can_act_as_audited?
      end

    assert !@nonconformity.must_be_approved?
    assert_equal 1, @nonconformity.approval_errors.size
    approval_errors = [I18n.t('nonconformity.errors.without_audited')]
    assert_equal approval_errors,
      @nonconformity.approval_errors

    @nonconformity.reload
    @nonconformity.finding_user_assignments =
      @nonconformity.finding_user_assignments.reject { |fua| fua.user.auditor? }
    assert !@nonconformity.must_be_approved?
    assert_equal 2, @nonconformity.approval_errors.size
    approval_errors << I18n.t('nonconformity.errors.without_auditor')
    assert_equal approval_errors, @nonconformity.approval_errors
  
    @nonconformity.reload
    @nonconformity.effect = ' '
    @nonconformity.audit_comments = '  '
    assert !@nonconformity.must_be_approved?
    assert_equal 4, @nonconformity.approval_errors.size
    approval_errors << I18n.t('nonconformity.errors.without_effect')
    approval_errors << I18n.t('nonconformity.errors.without_audit_comments')
    assert_equal approval_errors.sort, @nonconformity.approval_errors.sort
  end

  test 'work papers can be added to uneditable nonconformityes' do
    uneditable_nonconformity = Nonconformity.find(findings(
        :bcra_A4609_security_management_responsible_dependency_nonconformity_being_implemented).id)

    assert_no_difference 'Nonconformity.count' do
      assert_difference 'WorkPaper.count' do
        uneditable_nonconformity.update({
        :work_papers_attributes => {
            'new' => {
              :name => 'New post_workpaper name',
              :code => 'PTNC 20',
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
    uneditable_nonconformity = Nonconformity.find(findings(
        :iso_27000_security_policy_3_1_item_nonconformity).id)
    uneditable_nonconformity.final = true

    assert_no_difference ['Nonconformity.count', 'WorkPaper.count'] do
      assert_raise(RuntimeError) do
        uneditable_nonconformity.update({
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
    @nonconformity = Nonconformity.find(findings(
        :bcra_A4609_security_management_responsible_dependency_item_editable_being_implemented_nonconformity).id)
    assert @nonconformity.all_follow_up_dates.blank?
    assert !@nonconformity.rescheduled?
    assert_not_nil @nonconformity.follow_up_date

    old_date = @nonconformity.follow_up_date.clone

    assert @nonconformity.update_attribute(:follow_up_date, 10.days.from_now.to_date)
    assert @nonconformity.reload.all_follow_up_dates(nil, true).include?(old_date)
    assert @nonconformity.update_attribute(:follow_up_date, 15.days.from_now.to_date)
    assert @nonconformity.reload.all_follow_up_dates(nil, true).include?(old_date)
    assert @nonconformity.reload.all_follow_up_dates(nil, true).include?(
      10.days.from_now.to_date)
    assert @nonconformity.rescheduled?
  end
end
