require 'test_helper'

# Clase para probar el modelo "Finding"
class FindingTest < ActiveSupport::TestCase
  fixtures :findings, :control_objective_items

  # Función para inicializar las variables utilizadas en las pruebas
  def setup
    @finding = Finding.find findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id

    set_organization
  end

  # Prueba que se realicen las búsquedas como se espera
  test 'search' do
    finding = findings(:bcra_A4609_data_proccessing_impact_analisys_weakness)
    assert_kind_of Finding, @finding
    assert_equal finding.repeated_of_id, @finding.repeated_of_id
    assert_equal finding.control_objective_item_id,
      @finding.control_objective_item_id
    assert_equal finding.title, @finding.title
    assert_equal finding.review_code, @finding.review_code
    assert_equal finding.description, @finding.description
    assert_equal finding.answer, @finding.answer
    assert_equal finding.state, @finding.state
    assert_equal finding.solution_date, @finding.solution_date
    assert_equal finding.origination_date, @finding.origination_date
    assert_equal finding.audit_recommendations, @finding.audit_recommendations
    assert_equal finding.effect, @finding.effect
    assert_equal finding.risk, @finding.risk
    assert_equal finding.priority, @finding.priority
    assert_equal finding.follow_up_date, @finding.follow_up_date
  end

  # Prueba la creación de una debilidad
  test 'create' do
    assert_difference 'Finding.count' do
      @finding = @finding.class.list.new(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item_editable),
        :review_code => 'O020',
        :title => 'Title',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:notify],
        :origination_date => 1.day.ago.to_date,
        :solution_date => nil,
        :audit_recommendations => 'New proposed action',
        :effect => 'New effect',
        :risk => Finding.risks_values.first,
        :priority => Finding.priorities_values.first,
        :follow_up_date => nil,
        :finding_user_assignments_attributes => {
          :new_1 => {
            :user_id => users(:bare_user).id, :process_owner => false
          },
          :new_2 => {
            :user_id => users(:audited_user).id, :process_owner => true
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

      assert @finding.save, @finding.errors.full_messages.join('; ')
      assert_equal 'O020', @finding.review_code
    end

    # No se puede crear una observación de un objetivo que está en un informe
    # definitivo
    assert_no_difference 'Finding.count' do
      Finding.list.create(
        :control_objective_item =>
          control_objective_items(:bcra_A4609_data_proccessing_impact_analisys_item),
        :review_code => 'O020',
        :title => 'Title',
        :description => 'New description',
        :answer => 'New answer',
        :audit_comments => 'New audit comments',
        :state => Finding::STATUS[:notify],
        :origination_date => 35.days.from_now.to_date,
        :solution_date => 30.days.from_now.to_date,
        :audit_recommendations => 'New proposed action',
        :effect => 'New effect',
        :risk => Finding.risks_values.first,
        :priority => Finding.priorities_values.first,
        :follow_up_date => 2.days.from_now.to_date
      )
    end
  end

  # Prueba de actualización de una debilidad
  test 'update' do
    assert @finding.update(:description => 'Updated description'),
      @finding.errors.full_messages.join('; ')
    @finding.reload
    assert_equal 'Updated description', @finding.description
  end

  # Prueba de eliminación de debilidades
  test 'delete' do
    # No se puede eliminar si está en un informe definitivo
    assert_no_difference('Finding.count') { @finding.destroy }

    @finding = Finding.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_editable_weakness).id)

    # Y tampoco se puede eliminar si NO está en un informe definitivo
    assert_no_difference('Finding.count') { @finding.destroy }
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates blank attributes' do
    @finding.control_objective_item_id = nil
    @finding.review_code = '   '
    @finding.title = '   '
    @finding.description = '   '

    assert @finding.invalid?
    assert_error @finding, :control_objective_item_id, :blank
    assert_error @finding, :review_code, :blank
    assert_error @finding, :review_code, :invalid
    assert_error @finding, :title, :blank
    assert_error @finding, :description, :blank
  end

  test 'avoid title validation when audited' do
    Finding.current_user = users :audited_user

    @finding.title = '  '
    @finding.valid?

    assert @finding.errors[:title].blank?

    Finding.current_user = nil
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates special blank attributes' do
    # En estado "En proceso de implementación"
    @finding = Finding.find(
      findings(:bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id
    )
    @finding.follow_up_date = nil
    @finding.answer = '   '

    assert @finding.invalid?
    assert_error @finding, :follow_up_date, :blank
    assert_error @finding, :answer, :blank

    Finding.current_user = users :supervisor_user

    assert @finding.reload.update(
      :state => Finding::STATUS[:implemented_audited],
      :solution_date => 1.month.from_now)
    @finding.solution_date = nil

    Finding.current_user = nil

    assert @finding.invalid?
    assert_error @finding, :solution_date, :blank

    @finding = Finding.find(
      findings(:iso_27000_security_organization_4_2_item_editable_weakness_incomplete).id
    )

    @finding.state = Finding::STATUS[:revoked]
    @finding.audit_comments = '  '

    assert @finding.invalid?
    assert_error @finding, :audit_comments, :blank
  end

  test 'validates special not blank attributes' do
    finding = Finding.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_weakness).id)

    finding.follow_up_date = Date.today
    finding.solution_date = Date.tomorrow

    assert finding.invalid?
    assert_error finding, :follow_up_date, :must_be_blank
    assert_error finding, :solution_date, :must_be_blank
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates duplicated attributes' do
    another_finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)
    @finding.review_code = another_finding.review_code

    assert @finding.invalid?
    assert_error @finding, :review_code, :taken

    # Se puede duplicar si es de otro informe
    another_finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)
    @finding.review_code = another_finding.review_code
    assert @finding.valid?
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates length of attributes' do
    @finding.review_code = 'abcdd' * 52
    @finding.title = 'abcdd' * 52

    assert @finding.invalid?
    assert_error @finding, :review_code, :too_long, count: 255
    assert_error @finding, :title, :too_long, count: 255
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates well formated attributes' do
    @finding.update_column :state, Finding::STATUS[:incomplete]
    @finding.reload

    @finding.first_notification_date = '13/13/13'
    @finding.follow_up_date          = '13/13/13'
    @finding.solution_date           = '13/13/13'
    @finding.origination_date        = '13/13/13'

    assert @finding.invalid?
    assert_error @finding, :first_notification_date, :invalid_date
    assert_error @finding, :follow_up_date,          :invalid_date
    assert_error @finding, :solution_date,           :invalid_date
    assert_error @finding, :origination_date,        :invalid_date
  end

  test 'validates attributes encoding' do
    @finding.title = "\n\t"

    assert @finding.invalid?
    assert_error @finding, :title, :pdf_encoding
  end

  # Prueba que las validaciones del modelo se cumplan como es esperado
  test 'validates included attributes' do
    # Debe tener una fecha de implementación por el cambio de estado
    @finding.follow_up_date = 1.day.from_now.to_date
    @finding.state = @finding.next_status_list.values.reject do |s|
      s == @finding.state
    end.sort.last.next

    assert @finding.invalid?
    assert_error @finding, :state, :inclusion
  end

  test 'validates status' do
    next_status_list = @finding.next_status_list
    not_allowed_status = Finding::STATUS.values - next_status_list.values

    not_allowed_status.each do |not_allowed|
      @finding.state = not_allowed

      assert @finding.invalid?
      # Dependiendo del estado se validan más o menos cosas
      assert_error @finding, :state, :inclusion
    end
  end

  test 'validates exceptional status change' do
    finding = Finding.find(
      findings(:iso_27000_security_policy_3_1_item_weakness).id
    )

    finding.state = Finding::STATUS[:implemented]
    assert finding.save

    finding.state = Finding::STATUS[:being_implemented]
    assert finding.invalid?

    assert_error finding, :state, :must_have_a_comment

    finding.comments.build(
      :comment => 'Test comment',
      :user => users(:administrator_user)
    )

    assert finding.valid?

    finding.state = Finding::STATUS[:revoked]
    assert finding.invalid?

    assert_error finding, :state, :can_not_be_revoked
    assert_error finding, :state, :invalid
  end

  test 'validates implemented audited with work papers' do
    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness).id)

    finding.state = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today

    assert finding.work_papers.empty?
    assert finding.invalid?
    assert_error finding, :state, :must_have_a_work_paper
  end

  test 'validates audited users' do
    @finding.finding_user_assignments =
      @finding.finding_user_assignments.reject do |fua|
        fua.user.can_act_as_audited?
      end

    assert @finding.invalid?
    assert_error @finding, :finding_user_assignments, :invalid
  end

  test 'validates auditor users' do
    @finding.finding_user_assignments =
      @finding.finding_user_assignments.reject { |fua| fua.user.auditor? }

    assert @finding.invalid?
    assert_error @finding, :finding_user_assignments, :invalid
  end

  test 'validates supervisor or manager users' do
    @finding.finding_user_assignments =
      @finding.finding_user_assignments.reject { |fua| fua.user.supervisor? || fua.user.manager? }

    assert @finding.invalid?
    assert_error @finding, :finding_user_assignments, :invalid
  end

  test 'validate final state change only by supervisors' do
    Finding.current_user = users :auditor_user

    @finding = Finding.find(
      findings(:bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id
    )
    @finding.state = Finding::STATUS[:implemented_audited]
    @finding.solution_date = 1.month.from_now

    assert @finding.invalid?
    assert_error @finding, :state, :must_be_done_by_proper_role

    Finding.current_user = users :supervisor_user

    assert @finding.valid?
  end

  test 'stale function' do
    @finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)

    assert !@finding.stale?

    @finding.follow_up_date = 2.days.ago.to_date

    assert @finding.stale?
  end

  test 'next status list function' do
    Finding::STATUS.each do |status, value|
      keys = @finding.next_status_list(value).keys
      expected_keys = Finding::STATUS_TRANSITIONS_WITH_FINAL_REVIEW[status].map(&:to_s)

      assert_equal expected_keys.size, keys.size
      assert keys.all? { |k| expected_keys.include?(k) }
    end
  end

  test 'unconfirmed can not be changed to another than confirmed or unanswered' do
    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)
    finding.state = Finding::STATUS[:implemented]

    assert !finding.update(:state => Finding::STATUS[:implemented])
    assert finding.update(:state => Finding::STATUS[:confirmed])
  end

  test 'unconfirmed to confirmed after audited response' do
    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)

    assert finding.unconfirmed?
    assert_nil finding.confirmation_date
    assert finding.notifications.not_confirmed.any? { |n| n.user.can_act_as_audited? }

    finding.finding_answers.build(
      :answer => 'New administrator answer',
      :user => users(:supervisor_user)
    )

    # La respuesta es de un usuario supervisor
    assert finding.unconfirmed?
    assert finding.notifications.not_confirmed.any? { |n| n.user.can_act_as_audited? }

    finding.finding_answers.build(
      :answer => 'New audited answer',
      :user => users(:audited_user),
      :commitment_date => Date.today
    )

    assert finding.confirmed?
    assert_not_nil finding.confirmation_date
    assert !finding.notifications.not_confirmed.reload.any? { |n| n.user.can_act_as_audited? }
    assert_equal users(:audited_user).id,
      finding.notifications.detect { |n| n.user.can_act_as_audited? }.user_who_confirm.id
    assert finding.save
  end

  test 'unconfirmed with empty audited response must not change' do
    finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness_unconfirmed_for_notification).id)

    assert finding.unconfirmed?
    assert_nil finding.confirmation_date
    assert finding.notifications.not_confirmed.any? { |n| n.user.can_act_as_audited? }

    finding.finding_answers.build(
      :answer => '',
      :user => users(:audited_user)
    )

    assert !finding.confirmed?
    assert_nil finding.confirmation_date
    assert finding.notifications.not_confirmed.reload.any? { |n| n.user.can_act_as_audited? }
    assert !finding.save
  end

  test 'status change from confirmed must have an answer' do
    finding = Finding.find(findings(
        :bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity).id)

    finding.state = Finding::STATUS[:unanswered]

    assert finding.valid?, finding.errors.full_messages.join('; ')

    finding.answer = ''

    assert finding.invalid?
    assert_error finding, :answer, :blank
  end

  test 'dynamic functions' do
    # Funciones status?
    Finding::STATUS.each do |status, value|
      @finding.state = value
      assert @finding.send(:"#{status}?")

      Finding::STATUS.each do |k, v|
        unless k == status
          @finding.state = v
          assert !@finding.send(:"#{status}?")
        end
      end
    end

    # Funciones was_status?
    @finding.reload
    assert @finding.unanswered?

    @finding.state = Finding::STATUS[:confirmed]

    assert !@finding.unconfirmed?
    assert @finding.confirmed?
    assert @finding.was_unanswered?
    assert !@finding.was_confirmed?
  end

  test 'versions between' do
    assert_equal 0, @finding.versions_between(1.year.ago, 1.year.from_now).size
    assert @finding.update(:audit_comments => 'Updated comments')
    assert_equal 1, @finding.versions_between.size
    assert_equal 1, @finding.versions_between(1.year.ago, 1.year.from_now).size
    assert_equal 0, @finding.versions_between(1.minute.from_now,
      2.minutes.from_now).size
    assert_equal 1, @finding.versions_between(1.minute.ago,
      1.minute.from_now).size
    assert_equal 0, @finding.versions_between(2.minute.ago, 1.minute.ago).size
  end

  test 'versions since final review' do
    assert_equal 0, @finding.versions_after_final_review.size
    updated_at = @finding.updated_at.dup
    assert @finding.update(:audit_comments => 'Updated comments')
    assert_equal 1, @finding.versions_after_final_review.size
    assert_equal 0, @finding.versions_after_final_review(updated_at).size
    updated_at = @finding.reload.updated_at.dup

    assert @finding.update(:audit_comments => 'New updated comments')
    assert_equal 2, @finding.versions_after_final_review.size
    assert_equal 2, @finding.versions_after_final_review(updated_at + 1).size
    assert @finding.versions_after_final_review.first.update_attribute(
      :created_at, updated_at + 2)
    assert_equal 1, @finding.reload.versions_after_final_review(
      updated_at + 1).size
  end

  test 'status change history' do
    assert_equal 1, @finding.status_change_history.size
    assert @finding.update(:audit_comments => 'Updated comments')
    assert_equal 1, @finding.status_change_history.size

    Finding.current_user = users :supervisor_user

    assert @finding.update(:state => Finding::STATUS[:assumed_risk],
      :solution_date => Date.today)
    assert_equal 2, @finding.status_change_history.size

    Finding.current_user = nil
  end

  test 'mark as unconfirmed' do
    finding = Finding.find findings(
      :bcra_A4609_security_management_responsible_dependency_notify_oportunity).id

    assert finding.notify?
    assert finding.mark_as_unconfirmed
    assert finding.unconfirmed?
    assert_equal Date.today, finding.first_notification_date
  end

  test 'important dates' do
    finding = Finding.find findings(
      :iso_27000_security_policy_3_1_item_weakness_2_unconfirmed_for_notification).id

    # Fecha de notificación y de cambio de estado a Sin Respuesta
    assert_equal 2, finding.important_dates.size

    finding = Finding.find findings(
      :bcra_A4609_security_management_responsible_dependency_notify_oportunity).id

    assert_equal 0, finding.important_dates.size
    assert finding.mark_as_unconfirmed
    # Fecha de notificación y de cambio de estado a Sin Respuesta
    assert_equal 2, finding.important_dates.size

    finding.confirmed!
    assert finding.reload.confirmed?
    # Fecha de notificación, de confirmación y de cambio de estado a Sin Respuesta
    assert_equal 3, finding.important_dates.size
  end

  test 'notify changes to users' do
    new_user = User.find(users(:administrator_second_user).id)

    assert !@finding.finding_user_assignments.blank?
    assert !@finding.finding_user_assignments.detect{|fua| fua.user == new_user}

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.update(:description => 'Updated description')
    end

    @finding.finding_user_assignments.each do |fua|
      fua.mark_for_destruction if fua.user_id == users(:administrator_user).id
    end
    @finding.finding_user_assignments.build(:user => new_user)

    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.save
    end
  end

  test 'avoid notify changes to users' do
    new_user = User.find(users(:administrator_second_user).id)

    assert !@finding.finding_user_assignments.blank?
    assert !@finding.finding_user_assignments.detect{|fua| fua.user == new_user}

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.update(:description => 'Updated description')
    end

    @finding.finding_user_assignments.each do |fua|
      fua.mark_for_destruction if fua.user_id == users(:administrator_user).id
    end
    @finding.finding_user_assignments.build(:user => new_user)
    @finding.avoid_changes_notification = true

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.save
    end
  end

  test 'avoid notify changes to users if incomplete' do
    new_user = User.find(users(:administrator_second_user).id)
    fuas = @finding.finding_user_assignments.map do |fua|
      fua.attributes.reject { |k,v| k == 'id' }
    end
    finding = @finding.class.new(@finding.attributes.merge(
        'state' => Finding::STATUS[:incomplete],
        'review_code' => 'O099',
        'title' => 'Title',
        'control_objective_item_id' => control_objective_items(
          :bcra_A4609_security_management_responsible_dependency_item_editable).id,
        'finding_user_assignments_attributes' => fuas
      ).reject { |k,v| k == 'id' || k == 'type' }
    )

    assert finding.save
    assert !finding.finding_user_assignments.blank?
    assert !finding.finding_user_assignments.detect{|fua| fua.user == new_user}

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert finding.update(:description => 'Updated description')
    end

    finding.finding_user_assignments.each do |fua|
      fua.mark_for_destruction if fua.user_id == users(:administrator_user).id
    end
    finding.finding_user_assignments.build(:user => new_user)

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert finding.save
    end
  end

  test 'notify deletion of user' do
    assert !@finding.finding_user_assignments.blank?

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @finding.finding_user_assignments.each do |fua|
      fua.mark_for_destruction if fua.user_id == users(:administrator_user).id
    end

    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.save
    end
  end

  test 'has audited' do
    assert(
      @finding.finding_user_assignments.any? do |fua|
        fua.user.can_act_as_audited?
      end
    )

    assert @finding.finding_user_assignments.any? { |fua| fua.user.auditor? }

    assert @finding.has_auditor?
    assert @finding.has_audited?
    
    @finding.finding_user_assignments = 
      @finding.finding_user_assignments.reject do |fua|
        fua.user.can_act_as_audited?
      end

    assert @finding.has_auditor?
    assert !@finding.has_audited?
  end

  test 'has auditor' do
    assert(
      @finding.finding_user_assignments.any? do |fua|
        fua.user.can_act_as_audited?
      end
    )

    assert @finding.finding_user_assignments.any? { |fua| fua.user.auditor? }

    assert @finding.has_auditor?
    assert @finding.has_audited?
    
    @finding.finding_user_assignments =
      @finding.finding_user_assignments.reject { |fua| fua.user.auditor? }

    assert !@finding.has_auditor?
    assert @finding.has_audited?
  end

  test 'users for scaffold notification' do
    finding = Finding.find(findings(
        :iso_27000_security_organization_4_2_item_editable_weakness_unanswered_for_level_1_notification).id)
    user_for_levels = {
      1 => [users(:audited_user), users(:plain_manager_user)].sort,
      2 => [users(:audited_user), users(:plain_manager_user),
        users(:coordinator_manager_user)].sort,
      3 => [users(:audited_user), users(:plain_manager_user),
        users(:coordinator_manager_user), users(:general_manager_user)].sort,
      # No escala al presidente ya que pertenece a una organización diferente a la de la observación
      4 => [users(:audited_user), users(:plain_manager_user),
       users(:coordinator_manager_user), users(:general_manager_user)].sort
    }

    n = 0

    until (users = finding.users_for_scaffold_notification(n += 1)).empty?
      assert_equal user_for_levels[n].map(&:to_s).sort, users.map(&:to_s).sort
    end

    # Agrego al presidente a la organización
    OrganizationRole.create({
      :user => users(:president_user),
      :organization => finding.review.organization,
      :role => roles(:executive_manager_role)
    })

    # Ahora debe notificarlo
    user_for_levels[4] << users(:president_user)
    n = 0

    until (users = finding.users_for_scaffold_notification(n += 1)).empty?
      assert_equal user_for_levels[n].map(&:to_s).sort, users.map(&:to_s).sort
    end

  end

  test 'manager users for level' do
    finding = Finding.find(findings(
        :iso_27000_security_organization_4_2_item_editable_weakness_unanswered_for_level_1_notification).id)
    user_for_levels = {
      1 => [users(:plain_manager_user)],
      2 => [users(:coordinator_manager_user)],
      3 => [users(:general_manager_user)],
      4 => [users(:president_user)]
    }

    n = 0

    until (users = finding.manager_users_for_level(n += 1)).empty?
      assert_equal user_for_levels[n].map(&:to_s), users.map(&:to_s)
    end
  end

  test 'notification date for level' do
    finding = Finding.find(findings(
        :iso_27000_security_organization_4_2_item_editable_weakness_unanswered_for_level_1_notification).id)

    10.times do |n|
      first_notification_date = finding.first_notification_date.dup
      computed_date = finding.notification_date_for_level(n + 1)
      days_to_add = (finding.stale_confirmed_days +
          finding.stale_confirmed_days * (n + 1)).next

      until days_to_add == 0
        first_notification_date += 1.day
        days_to_add -= 1 unless [0, 6].include?(first_notification_date.wday)
      end

      assert_equal computed_date, first_notification_date
    end
  end

  test 'commitment date' do
    assert_nil @finding.commitment_date
    assert_difference '@finding.finding_answers.count' do
      @finding.finding_answers.create(
        :answer => 'New answer',
        :commitment_date => 10.days.from_now.to_date,
        :user => users(:audited_user),
        :notify_users => false
      )
    end
    assert_equal 10.days.from_now.to_date, @finding.commitment_date
  end

  test 'mark as duplicated' do
    finding = Finding.find(findings(
        :iso_27000_security_organization_4_2_item_editable_weakness_unanswered_for_level_1_notification).id)
    repeated_of = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)

    assert_equal 0, finding.repeated_ancestors.size
    assert_equal 0, repeated_of.repeated_children.size
    assert_not_equal repeated_of.origination_date, finding.origination_date
    assert !repeated_of.repeated?
    assert finding.update(:repeated_of_id => repeated_of.id)
    assert repeated_of.reload.repeated?
    assert finding.reload.repeated_of
    assert_equal repeated_of.origination_date, finding.origination_date
    assert_equal 1, finding.repeated_ancestors.size
    assert_equal 1, repeated_of.repeated_children.size
    assert_equal repeated_of, finding.repeated_root

    # No se puede eliminar una observación reiterada
    assert_no_difference 'Finding.count' do
      assert !finding.destroy
    end

    # Intentar asignar otra relacionada
    repeated_of = Finding.find(
      findings(:iso_27000_security_policy_3_1_item_weakness).id)

    assert_raise RuntimeError do
      finding.update(:repeated_of_id => repeated_of.id)
    end
  end

  test 'undo reiteration' do
    finding = Finding.find(findings(
        :iso_27000_security_organization_4_2_item_editable_weakness_unanswered_for_level_1_notification).id)
    repeated_of = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)
    repeated_of_original_state = repeated_of.state

    assert !repeated_of.repeated?
    assert finding.update(:repeated_of_id => repeated_of.id)
    assert repeated_of.reload.repeated?
    assert finding.reload.repeated_of

    finding.undo_reiteration

    assert !repeated_of.reload.repeated?
    assert_nil finding.reload.repeated_of
    assert_equal repeated_of_original_state, repeated_of.state
  end

  test 'not mark as duplicated if repeated_of is not included in review' do
    finding = Finding.find(findings(
        :iso_27000_security_organization_4_2_item_editable_weakness_unanswered_for_level_1_notification).id)
    repeated_of = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)

    finding.review.finding_review_assignments.clear

    assert_raise RuntimeError do
      finding.update(:repeated_of_id => repeated_of.id)
    end
  end

  test 'follow up pdf' do
    assert !File.exist?(@finding.absolute_follow_up_pdf_path)

    assert_nothing_raised do
      @finding.follow_up_pdf(organizations(:cirope))
    end

    assert File.exist?(@finding.absolute_follow_up_pdf_path)
    assert File.size(@finding.absolute_follow_up_pdf_path) > 0

    FileUtils.rm @finding.absolute_follow_up_pdf_path
  end

  test 'to pdf' do
    assert !File.exist?(@finding.absolute_pdf_path)

    assert_nothing_raised do
      @finding.to_pdf(organizations(:cirope))
    end

    assert File.exist?(@finding.absolute_pdf_path)
    assert File.size(@finding.absolute_pdf_path) > 0

    FileUtils.rm @finding.absolute_pdf_path
  end

  test 'to csv' do
    csv = Finding.all.to_csv
    rows = CSV.parse csv, col_sep: ';'

    assert_equal Finding.count + 1, rows.length
  end

  test 'notify users if they are selected for notification' do
    @finding.users_for_notification = [users(:administrator_user).id]

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      assert @finding.save
    end

    response = ActionMailer::Base.deliveries.first

    assert response.subject.include?(
      I18n.t('notifier_mailer.notify_new_finding.title')
    )
  end

  test 'not notify users if is incomplete' do
    fuas = @finding.finding_user_assignments.map do |fua|
      fua.attributes.reject { |k,v| k == 'id' }
    end
    finding = @finding.class.new(@finding.attributes.merge(
        'state' => Finding::STATUS[:incomplete],
        'review_code' => 'O099',
        'title' => 'Title',
        'control_objective_item_id' => control_objective_items(
          :bcra_A4609_security_management_responsible_dependency_item_editable).id,
        'finding_user_assignments_attributes' => fuas
      ).reject { |k,v| k == 'id' || k == 'type' }
    )
    assert finding.save

    finding.users_for_notification = [users(:administrator_user).id]

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      assert finding.save
    end
  end

  test 'notify for stale and unconfirmed findings' do
    Organization.current_id = nil
    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)
    assert_equal 2, Finding.unconfirmed_for_notification.size

    review_codes_by_user = {}

    Finding.unconfirmed_for_notification.each do |finding|
      finding.users.each do |user|
        assert user.notifications.not_confirmed.all? {|n| !n.findings.empty?}
        review_codes_by_user[user] ||= []
        user.notifications.not_confirmed.each do |n|
          review_codes_by_user[user] |=
            n.findings.unconfirmed_for_notification.map(&:review_code)
        end
      end
    end

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      Finding.notify_for_unconfirmed_for_notification_findings
    end

    review_codes_by_user.each do |user, review_codes|
      ActionMailer::Base.deliveries.each do |mail|
        if mail.to.include?(user.email)
          assert review_codes.all? { |r_c| mail.body.match(Regexp.new(r_c)) }
        end
      end
    end

    Finding.unconfirmed_for_notification.each do |finding|
      begin
        finding.first_notification_date -=
          FINDING_STALE_UNCONFIRMED_DAYS.next.day
      end while [0, 6].include?(finding.first_notification_date.wday)
      assert finding.save
    end

    assert Finding.unconfirmed_for_notification.empty?
  end

  test 'warning users about findings expiration' do
    Organization.current_id = nil
    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)
    assert_equal 1, Finding.next_to_expire.size

    before_expire = (FINDING_WARNING_EXPIRE_DAYS - 1).days.from_now_in_business.
      to_date
    expire = FINDING_WARNING_EXPIRE_DAYS.days.from_now_in_business.to_date

    review_codes_by_user = {}

    Finding.next_to_expire.each do |finding|
      finding.finding_user_assignments.map(&:user).each do |user|
        assert !user.findings.next_to_expire.empty?
        review_codes_by_user[user] ||= []
        review_codes_by_user[user] |=
          user.findings.next_to_expire.map(&:review_code)
      end
    end

    assert(Finding.next_to_expire.all? do |finding|
        finding.follow_up_date.between?(before_expire, expire) ||
          finding.solution_date.between?(before_expire, expire)
      end)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 7 do
      Finding.warning_users_about_expiration
    end

    review_codes_by_user.each do |user, review_codes|
      ActionMailer::Base.deliveries.each do |mail|
        if mail.to.include?(user.email)
          assert review_codes.all? { |r_c| mail.body.match(Regexp.new(r_c)) }
        end
      end
    end
  end

  test 'remember users about expired findings' do
    Organization.current_id = nil
    assert_equal 3, Finding.expired.size

    review_codes_by_user = {}

    Finding.expired.each do |finding|
      finding.finding_user_assignments.map(&:user).each do |user|
        assert !user.findings.expired.empty?
        review_codes_by_user[user] ||= []
        review_codes_by_user[user] |= user.findings.expired.map(&:review_code)
      end
    end

    assert(Finding.expired.all? { |finding| finding.follow_up_date < Time.zone.today })

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', 6 do
      Finding.remember_users_about_expiration
    end

    review_codes_by_user.each do |user, review_codes|
      ActionMailer::Base.deliveries.each do |mail|
        if mail.to.include?(user.email)
          assert review_codes.all? { |r_c| mail.body.match(Regexp.new(r_c)) }
        end
      end
    end
  end

  test 'mark stale and confirmed findings as unanswered' do
    Organization.current_id = nil
    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)
    findings = Finding.confirmed_and_stale.select do |finding|
      !finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
    end
    users = findings.inject([]) do |u, finding|
      u | finding.finding_user_assignments.map(&:user)
    end

    review_codes_by_user = {}

    users.each do |user|
      findings_by_user = user.findings.confirmed_and_stale.select do |finding|
        !finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
      end

      assert !findings_by_user.empty?
      review_codes_by_user[user] = findings_by_user.map(&:review_code)
    end

    assert !review_codes_by_user.empty?
    unanswered_finding = Finding.where(
      :state => Finding::STATUS[:unanswered]
    ).count
    assert_not_equal 0, findings.size

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size', users.size do
      Finding.mark_as_unanswered_if_necesary
    end

    review_codes_by_user.each do |user, review_codes|
      ActionMailer::Base.deliveries.each do |mail|
        if mail.to.include?(user.email)
          assert review_codes.all? { |r_c| mail.body.match(Regexp.new(r_c)) }
        end
      end
    end

    assert_not_equal unanswered_finding, Finding.where(
      :state => Finding::STATUS[:unanswered]
    ).count
    assert Finding.confirmed_and_stale.empty?
  end

  test 'not mark stale and confirmed findings if has an answer' do
    Organization.current_id = nil

    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)
    unanswered_findings = Finding.where(
      :state => Finding::STATUS[:unanswered]
    ).count
    assert_equal 1, Finding.confirmed_and_stale.size

    Finding.confirmed_and_stale.each do |finding|
      finding.finding_answers.create(
        :answer => 'New answer',
        :user => users(:audited_user)
      )
    end

    counts = ['Finding.confirmed_and_stale.count',
      'ActionMailer::Base.deliveries.size']
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference counts do
      Finding.mark_as_unanswered_if_necesary
    end

    assert_equal unanswered_findings, Finding.where(
      :state => Finding::STATUS[:unanswered]
    ).count
    assert !Finding.confirmed_and_stale.empty?
  end

  test 'notify manager if necesary' do
    Organization.current_id = nil
    # Sólo funciona si no es un fin de semana
    assert ![0, 6].include?(Date.today.wday)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    users_by_level_for_notification = {1 => [], 2 => [], 3 => [], 4 => []}
    finding_ids = []

    n = 0

    until (findings = Finding.unanswered_and_stale(n += 1)).empty?
      assert_equal 1, findings.size

      findings.each do |finding|
      # No debe escalar al presidente (4to nivel)  ya que no pertenece a la organización de la observación
        unless n == 4
          users = finding.users_for_scaffold_notification(n)
          has_audited_comments = finding.finding_answers.reload.any? do |fa|
            fa.user.can_act_as_audited?
          end

          assert users.present?

          if users.present? && !has_audited_comments
            finding_ids << finding.id
            users_by_level_for_notification[n] |= finding.users |
            finding.users_for_scaffold_notification(n)
          end
        end
      end
    end

    # No escala al nivel 4
    assert_difference 'ActionMailer::Base.deliveries.size', 3 do
      level_counts = {}

      finding_ids.each do |f_id|
        level_counts[f_id] = Finding.find(f_id).notification_level
      end

      Finding.notify_manager_if_necesary

      finding_ids.each do |f_id|
        assert_equal level_counts[f_id].next,
          Finding.find(f_id).notification_level
      end
    end

    mails_by_level = mails = []

    ActionMailer::Base.deliveries.each_with_index do |mail,i|
      mails_by_level << mail.to.sort
    end

    users_by_level_for_notification.each do |i, users|
      mails = mails_by_level[i - 1] || []

      assert_equal users.map(&:email).sort, mails.sort
    end
  end

  test 'work papers can be added to uneditable findings' do
    uneditable_finding = Finding.find(findings(
        :bcra_A4609_security_management_responsible_dependency_weakness_being_implemented).id)

    assert_no_difference 'Finding.count' do
      assert_difference 'WorkPaper.count' do
        uneditable_finding.update({
            :work_papers_attributes => {
              '1_new' => {
                :name => 'New post_workpaper name',
                :code => 'PTO 20',
                :number_of_pages => '10',
                :description => 'New post_workpaper description',
                :organization_id => organizations(:cirope).id,
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
    uneditable_finding = Finding.find(findings(
        :iso_27000_security_policy_3_1_item_weakness).id)
    uneditable_finding.final = true

    assert_no_difference ['Finding.count', 'WorkPaper.count'] do
      assert_raise(RuntimeError) do
        uneditable_finding.update({
        :work_papers_attributes => {
            '1_new' => {
              :name => 'New post_workpaper name',
              :code => 'New post_workpaper code',
              :number_of_pages => '10',
              :description => 'New post_workpaper description',
              :organization_id => organizations(:cirope).id,
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
end
