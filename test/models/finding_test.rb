require 'test_helper'

class FindingTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @finding = findings :unanswered_weakness

    set_organization
  end

  test 'create' do
    assert_difference 'Finding.count' do
      assert_difference 'Tagging.count', 2 do
        @finding.class.list.create!(
          control_objective_item: control_objective_items(:impact_analysis_item_editable),
          review_code: 'O020',
          title: 'Title',
          description: 'New description',
          answer: 'New answer',
          audit_comments: 'New audit comments',
          state: Finding::STATUS[:notify],
          origination_date: 1.day.ago.to_date,
          solution_date: nil,
          audit_recommendations: 'New proposed action',
          effect: 'New effect',
          risk: Finding.risks_values.first,
          priority: Finding.priorities_values.first,
          follow_up_date: nil,
          compliance: 'no',
          operational_risk: ['internal fraud'],
          impact: ['econimic', 'regulatory'],
          internal_control_components: ['risk_evaluation', 'monitoring'],
          finding_user_assignments_attributes: {
            new_1: {
              user_id: users(:audited).id, process_owner: true
            },
            new_2: {
              user_id: users(:auditor).id, process_owner: false
            },
            new_3: {
              user_id: users(:supervisor).id, process_owner: false
            }
          },
          taggings_attributes: {
            new_1: {
              tag_id: tags(:important).id
            },
            new_2: {
              tag_id: tags(:pending).id
            }
          }
        )
      end
    end
  end

  test 'control objective from final review can not be used to create new finding' do
    assert_no_difference 'Finding.count' do
      finding = Finding.list.create(
        control_objective_item: control_objective_items(:impact_analysis_item),
        review_code: 'O020',
        title: 'Title',
        description: 'New description',
        answer: 'New answer',
        audit_comments: 'New audit comments',
        state: Finding::STATUS[:notify],
        origination_date: 35.days.from_now.to_date,
        audit_recommendations: 'New proposed action',
        effect: 'New effect',
        risk: Finding.risks_values.first,
        priority: Finding.priorities_values.first,
        follow_up_date: 2.days.from_now.to_date,
        compliance: 'no',
        operational_risk: ['internal fraud'],
        impact: ['econimic', 'regulatory'],
        internal_control_components: ['risk_evaluation', 'monitoring'],
        finding_user_assignments_attributes: {
          new_1: {
            user_id: users(:audited).id, process_owner: true
          },
          new_2: {
            user_id: users(:auditor).id, process_owner: false
          },
          new_3: {
            user_id: users(:supervisor).id, process_owner: false
          }
        },
        taggings_attributes: {
          new_1: {
            tag_id: tags(:important).id
          }
        }
      )

      assert_includes finding.errors.full_messages, I18n.t('finding.readonly')
    end
  end

  test 'delete' do
    # On a final review, can not be destroyed
    assert_no_difference('Finding.count') { @finding.destroy }

    finding = findings :unconfirmed_weakness

    # Without final review, also can not be destroyed =)
    assert_no_difference('Finding.count') { finding.destroy }
  end

  test 'validates blank attributes' do
    @finding.control_objective_item_id = nil
    @finding.review_code               = '   '
    @finding.title                     = '   '
    @finding.description               = '   '

    assert @finding.invalid?
    assert_error @finding, :control_objective_item_id, :blank
    assert_error @finding, :review_code, :blank
    assert_error @finding, :review_code, :invalid
    assert_error @finding, :title, :blank
    assert_error @finding, :description, :blank
  end

  test 'validates special blank attributes' do
    finding                = findings :being_implemented_weakness
    finding.answer         = '   '
    finding.follow_up_date = nil

    assert finding.invalid?
    assert_error finding, :follow_up_date, :blank
    assert_error finding, :answer, :blank
  end

  test 'validates solution date is not blank when implemented audited' do
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = nil

    assert finding.invalid?
    assert_error finding, :solution_date, :blank
  end

  test 'validates revoked findings must have audit comments' do
    finding                = findings :incomplete_weakness
    finding.state          = Finding::STATUS[:revoked]
    finding.audit_comments = '  '

    assert finding.invalid?
    assert_error finding, :audit_comments, :blank
  end

  test 'validates special not blank attributes' do
    @finding.follow_up_date = Time.zone.today
    @finding.solution_date  = Time.zone.tomorrow

    assert @finding.invalid?
    assert_error @finding, :follow_up_date, :must_be_blank
    assert_error @finding, :solution_date, :must_be_blank
  end

  test 'validates duplicated attributes' do
    finding = @finding.dup

    assert finding.invalid?
    assert_error finding, :review_code, :taken

    # Not in the same review
    other = findings :unconfirmed_for_notification_weakness

    @finding.review_code = other.review_code
    assert @finding.valid?
  end

  test 'validates length of attributes' do
    @finding.review_code = 'abcdd' * 52
    @finding.title       = 'abcdd' * 52

    assert @finding.invalid?
    assert_error @finding, :review_code, :too_long, count: 255
    assert_error @finding, :title, :too_long, count: 255
  end

  test 'validates well formated attributes' do
    @finding.update_column :state, Finding::STATUS[:incomplete]

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

  test 'validates included attributes' do
    @finding.follow_up_date = 1.day.from_now.to_date
    @finding.state          = @finding.next_status_list.values.sort.last.next

    assert @finding.invalid?
    assert_error @finding, :state, :inclusion
  end

  test 'validates status' do
    next_status_list   = @finding.next_status_list
    not_allowed_status = Finding::STATUS.values - next_status_list.values

    assert not_allowed_status.any?

    not_allowed_status.each do |not_allowed|
      @finding.state = not_allowed

      assert @finding.invalid?
      assert_error @finding, :state, :inclusion
    end
  end

  test 'validates implemented can be back at being implemented if comment' do
    finding       = findings :being_implemented_weakness_on_final
    finding.state = Finding::STATUS[:implemented]

    finding.save!

    finding.state = Finding::STATUS[:being_implemented]

    assert finding.invalid?
    assert_error finding, :state, :must_have_a_comment

    finding.comments.build(
      user:    users(:administrator),
      comment: 'Test comment'
    )

    assert finding.valid?
  end

  test 'validates implemented audited can be back at implemented if comment' do
    finding                 = findings :being_implemented_weakness_on_final
    finding.state           = Finding::STATUS[:implemented_audited]
    finding.solution_date   = Time.zone.today
    finding.skip_work_paper = true

    Current.user = users :supervisor

    cfr = finding.review.conclusion_final_review

    def cfr.can_be_destroyed?; true; end

    cfr.destroy!

    finding.save!
    finding.reload

    finding.state         = Finding::STATUS[:implemented]
    finding.solution_date = nil

    assert finding.invalid?
    assert_error finding, :state, :must_have_a_comment

    finding.comments.build(
      user:    users(:administrator),
      comment: 'Test comment'
    )

    assert finding.valid?
  end

  test 'validates expired can be back at implemented if comment' do
    finding                = findings :being_implemented_weakness_on_final
    finding.state          = Finding::STATUS[:expired]
    finding.follow_up_date = nil
    finding.solution_date  = Time.zone.today

    Current.user = users :supervisor

    cfr = finding.review.conclusion_final_review

    def cfr.can_be_destroyed?; true; end

    cfr.destroy!

    finding.save!
    finding.reload

    finding.state          = Finding::STATUS[:implemented]
    finding.follow_up_date = Time.zone.today
    finding.solution_date  = nil

    assert finding.invalid?
    assert_error finding, :state, :must_have_a_comment

    finding.comments.build(
      user:    users(:administrator),
      comment: 'Test comment'
    )

    assert finding.valid?
  end

  test 'validates revoked transition is only possible when repeated of' do
    finding       = findings :being_implemented_weakness_on_final
    finding.state = Finding::STATUS[:revoked]

    assert finding.invalid?
    assert_error finding, :state, :can_not_be_revoked
    assert_error finding, :state, :invalid
  end

  test 'validates implemented audited must have work papers' do
    finding               = findings :being_implemented_weakness_on_final
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Time.zone.today

    assert finding.work_papers.empty?
    assert finding.invalid?
    assert_error finding, :state, :must_have_a_work_paper
  end

  test 'validates implemented audited can skip work paper validation' do
    finding               = findings :being_implemented_weakness_on_final
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Time.zone.today

    Current.user = users :supervisor
    finding.skip_work_paper = true

    assert finding.work_papers.empty?
    assert finding.valid?
  end

  test 'validates audited user must be present' do
    @finding.finding_user_assignments =
      @finding.finding_user_assignments.reject do |fua|
        fua.user.can_act_as_audited?
      end

    assert @finding.invalid?
    assert_error @finding, :finding_user_assignments, :invalid
  end

  test 'validates auditor user must be present' do
    @finding.finding_user_assignments =
      @finding.finding_user_assignments.reject do |fua|
        fua.user.auditor?
      end

    assert @finding.invalid?
    assert_error @finding, :finding_user_assignments, :invalid
  end

  test 'validates supervisor or manager user must be present' do
    @finding.finding_user_assignments =
      @finding.finding_user_assignments.reject do |fua|
        fua.user.supervisor? || fua.user.manager?
      end

    assert @finding.invalid?
    assert_error @finding, :finding_user_assignments, :invalid
  end

  test 'validate final state can be changed only by supervisors' do
    skip if DISABLE_FINDING_FINAL_STATE_ROLE_VALIDATION

    Current.user = users :auditor

    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = 1.month.from_now

    assert finding.invalid?
    assert_error finding, :state, :must_be_done_by_proper_role

    Current.user = users :supervisor

    assert finding.valid?
  end

  test 'validate final state can be changed by any auditor' do
    skip unless DISABLE_FINDING_FINAL_STATE_ROLE_VALIDATION

    Current.user = users :auditor

    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = 1.month.from_now

    assert finding.valid?

    Current.user = users :supervisor

    assert finding.valid?
  end

  test 'import users' do
    finding = @finding.dup
    review  = @finding.review

    assert finding.finding_user_assignments.blank?

    finding.import_users

    expected_users = @finding.review.review_user_assignments.map(&:user).sort

    assert finding.finding_user_assignments.present?
    assert_equal expected_users, finding.finding_user_assignments.map(&:user).sort
  end

  test 'stale function' do
    finding = findings :being_implemented_weakness

    refute finding.stale?

    finding.follow_up_date = 2.days.ago.to_date

    assert finding.stale?
  end

  test 'next status list function' do
    Finding::STATUS.each do |status, value|
      keys          = @finding.next_status_list(value).keys
      expected_keys = Finding::STATUS_TRANSITIONS_WITH_FINAL_REVIEW[status].map(&:to_s)

      assert_equal expected_keys.sort, keys.sort
    end
  end

  test 'unconfirmed can not be changed to another than confirmed or unanswered' do
    finding       = findings :unconfirmed_for_notification_weakness
    finding.state = Finding::STATUS[:implemented]

    assert finding.invalid?

    finding.state = Finding::STATUS[:confirmed]

    assert finding.valid?
  end

  test 'unconfirmed does not change to confirmed after auditor comment' do
    finding = findings :unconfirmed_for_notification_weakness

    finding.finding_answers.build(
      answer: 'New auditor answer',
      user:   users(:auditor)
    )

    assert finding.unconfirmed?
    assert finding.notifications.not_confirmed.any? { |n| n.user.can_act_as_audited? }
  end

  test 'unconfirmed change to confirmed after audited comment' do
    finding = findings :unconfirmed_for_notification_weakness

    finding.finding_answers.build(
      user:            users(:audited),
      answer:          'New audited answer',
      commitment_date: Time.zone.today
    )

    assert finding.confirmed?
    assert_equal Time.zone.today, finding.confirmation_date
    assert finding.notifications.confirmed.any? { |n| n.user.can_act_as_audited? }
    assert_equal users(:audited).id,
      finding.notifications.confirmed.take.user_who_confirm.id
    assert finding.save
  end

  test 'unconfirmed with empty audited response must not change' do
    finding = findings :unconfirmed_for_notification_weakness

    finding.finding_answers.build(
      user:   users(:audited),
      answer: ''
    )

    assert finding.unconfirmed?
    assert finding.confirmation_date.blank?
    assert finding.notifications.not_confirmed.any? { |n| n.user.can_act_as_audited? }
    refute finding.save
  end

  test 'current situation is updated on audited response' do
    @finding.update! current_situation_verified: true

    @finding.finding_answers.build(
      user:            users(:audited),
      answer:          'New audited answer',
      commitment_date: Time.zone.today
    )

    @finding.save!

    assert_equal 'New audited answer', @finding.current_situation
    refute @finding.current_situation_verified
  end

  test 'current situation is not updated on auditor response' do
    @finding.update! current_situation_verified: true

    @finding.finding_answers.build(
      user:            users(:auditor),
      answer:          'New audited answer',
      commitment_date: Time.zone.today
    )

    @finding.save!

    assert_not_equal 'New audited answer', @finding.current_situation
    assert @finding.current_situation_verified
  end

  test 'status change from confirmed must have an answer' do
    finding        = findings :confirmed_oportunity
    finding.state  = Finding::STATUS[:unanswered]
    finding.answer = ''

    assert finding.invalid?
    assert_error finding, :answer, :blank
  end

  test 'dynamic status functions' do
    Finding::STATUS.each do |status, value|
      @finding.state = value
      assert @finding.send(:"#{status}?")

      Finding::STATUS.each do |k, v|
        unless k == status
          @finding.state = v

          refute @finding.send(:"#{status}?")
        end
      end
    end
  end

  test 'dynamic _was_ status functions' do
    @finding.state = Finding::STATUS[:confirmed]

    assert @finding.was_unanswered?
    refute @finding.was_confirmed?
  end

  test 'versions between' do
    @finding.update! audit_comments: 'Updated comments'

    assert_equal 1, @finding.versions_between.size
    assert_equal 1, @finding.versions_between(1.year.ago, 1.year.from_now).size
    assert_equal 0, @finding.versions_between(1.minute.from_now, 2.minutes.from_now).size
    assert_equal 1, @finding.versions_between(1.minute.ago, 1.minute.from_now).size
    assert_equal 0, @finding.versions_between(2.minute.ago, 1.minute.ago).size
  end

  test 'versions since final review' do
    updated_at = @finding.updated_at.dup

    @finding.update! audit_comments: 'Updated comments'

    assert_equal 1, @finding.versions_after_final_review.size
    assert_equal 0, @finding.versions_after_final_review(updated_at).size

    updated_at = @finding.updated_at.dup

    @finding.update! audit_comments: 'New updated comments'

    assert_equal 2, @finding.versions_after_final_review.size
    assert_equal 2, @finding.versions_after_final_review(updated_at + 1).size

    @finding.versions_after_final_review.take.update_column :created_at, updated_at + 2

    assert_equal 1, @finding.reload.versions_after_final_review(updated_at + 1).size
  end

  test 'status change history' do
    assert_no_difference '@finding.status_change_history.size' do
      @finding.update! audit_comments: 'Updated comments'
    end

    Current.user = users :supervisor

    assert_difference '@finding.status_change_history.size' do
      @finding.update!(
        state:         Finding::STATUS[:assumed_risk],
        solution_date: Date.today
      )
    end
  end

  test 'mark as unconfirmed' do
    finding = findings :notify_oportunity

    assert finding.mark_as_unconfirmed
    assert finding.unconfirmed?
    assert_equal Time.zone.today, finding.first_notification_date
  end

  test 'important dates' do
    finding = findings :unconfirmed_for_notification_weakness

    # Notification date and unanswered date
    assert_equal 2, finding.important_dates.size

    finding = findings :notify_oportunity

    assert_equal 0, finding.important_dates.size
    assert finding.mark_as_unconfirmed
    # Notification date and unanswered date
    assert_equal 2, finding.important_dates.size

    finding.confirmed!

    assert finding.confirmed?
    # Notification date, confirmation date and unanswered date
    assert_equal 3, finding.important_dates.size
  end

  test 'notify user changes to users' do
    new_user = users :administrator_second

    assert @finding.finding_user_assignments.present?
    assert @finding.finding_user_assignments.all? { |fua| fua.user != new_user }

    assert_no_enqueued_emails do
      @finding.update! description: 'Updated description'
    end

    @finding.finding_user_assignments.each do |fua|
      fua.mark_for_destruction if fua.user_id == users(:administrator).id
    end

    @finding.finding_user_assignments.build(user: new_user)

    assert_enqueued_emails 1 do
      @finding.save!
    end
  end

  test 'avoid notify user changes when avoid flag is set' do
    new_user = users :administrator_second

    assert @finding.finding_user_assignments.present?
    assert_nil @finding.finding_user_assignments.detect{ |fua| fua.user == new_user }


    assert_no_enqueued_emails do
      @finding.update! description: 'Updated description'
    end

    @finding.finding_user_assignments.each do |fua|
      fua.mark_for_destruction if fua.user_id == users(:administrator).id
    end

    @finding.finding_user_assignments.build(user: new_user)
    @finding.avoid_changes_notification = true

    assert_no_enqueued_emails do
      assert @finding.save
    end
  end

  test 'avoid notify changes to users if incomplete' do
    new_user = users :administrator_second
    finding  = findings :incomplete_weakness

    assert finding.finding_user_assignments.present?
    assert_nil finding.finding_user_assignments.detect{ |fua| fua.user == new_user }

    assert_no_enqueued_emails do
      finding.update! description: 'Updated description'
    end

    finding.finding_user_assignments.each do |fua|
      fua.mark_for_destruction if fua.user_id == users(:administrator).id
    end

    finding.finding_user_assignments.build(user: new_user)

    assert_no_enqueued_emails do
      finding.save!
    end
  end

  test 'notify user deletion' do
    @finding.finding_user_assignments.each do |fua|
      fua.mark_for_destruction if fua.user_id == users(:administrator).id
    end

    assert_enqueued_emails 1 do
      @finding.save!
    end
  end

  test 'has audited' do
    assert @finding.has_auditor?
    assert @finding.has_audited?

    @finding.finding_user_assignments =
      @finding.finding_user_assignments.reject do |fua|
        fua.user.can_act_as_audited?
      end

    assert @finding.has_auditor?
    refute @finding.has_audited?
  end

  test 'has auditor' do
    assert @finding.has_auditor?
    assert @finding.has_audited?

    @finding.finding_user_assignments =
      @finding.finding_user_assignments.reject { |fua| fua.user.auditor? }

    refute @finding.has_auditor?
    assert @finding.has_audited?
  end

  test 'users for scaffold notification' do
    finding         = findings :unanswered_for_level_1_notification
    user_for_levels = {
      1 => [
        users(:audited),
        users(:plain_manager)
      ].sort,
      2 => [
        users(:audited),
        users(:plain_manager),
        users(:coordinator_manager)
      ].sort,
      3 => [
        users(:audited),
        users(:plain_manager),
        users(:coordinator_manager),
        users(:general_manager)
      ].sort,
      # Not to president since he belongs to other organization
      4 => [
        users(:audited),
        users(:plain_manager),
        users(:coordinator_manager),
        users(:general_manager)
      ].sort
    }

    n = 0

    while (users = finding.users_for_scaffold_notification(n += 1)).present?
      assert_equal user_for_levels[n].map(&:to_s).sort, users.map(&:to_s).sort
    end

    # Lets join the president
    OrganizationRole.create! user:         users(:president),
                             organization: finding.review.organization,
                             role:         roles(:executive_manager_role)

    user_for_levels[4] << users(:president)
    n = 0

    while (users = finding.users_for_scaffold_notification(n += 1)).present?
      assert_equal user_for_levels[n].map(&:to_s).sort, users.map(&:to_s).sort
    end
  end

  test 'manager users for level' do
    finding         = findings :unanswered_for_level_1_notification
    user_for_levels = {
      1 => [users(:plain_manager)],
      2 => [users(:coordinator_manager)],
      3 => [users(:general_manager)],
      4 => [users(:president)]
    }

    n = 0

    while (users = finding.manager_users_for_level(n += 1)).present?
      assert_equal user_for_levels[n].map(&:to_s), users.map(&:to_s)
    end
  end

  test 'notification date for level' do
    finding = findings :unanswered_for_level_1_notification

    5.times do |n|
      first_notification_date = finding.first_notification_date.dup
      computed_date           = finding.notification_date_for_level(n + 1)
      days_to_add             = finding.stale_confirmed_days +
                                finding.stale_confirmed_days * (n + 1)

      until days_to_add == 0
        first_notification_date += 1.day
        days_to_add -= 1 if first_notification_date.workday?
      end

      assert_equal computed_date, first_notification_date
    end
  end

  test 'last commitment date' do
    assert_nil @finding.last_commitment_date

    @finding.finding_answers.create! answer:          'New answer',
                                     user:            users(:audited),
                                     commitment_date: 10.days.from_now.to_date,
                                     notify_users:    false

    assert_equal 10.days.from_now.to_date, @finding.last_commitment_date

    @finding.finding_answers.create! answer:          'New answer',
                                     user:            users(:audited),
                                     commitment_date: 20.days.from_now.to_date,
                                     notify_users:    false

    assert_equal 20.days.from_now.to_date, @finding.last_commitment_date
  end

  test 'first follow up date' do
    @finding.state          = Finding::STATUS[:being_implemented]
    @finding.follow_up_date = Time.zone.today

    @finding.save!

    assert @finding.reload.first_follow_up_date.present?
    assert @finding.follow_up_date.present?
    assert_equal @finding.follow_up_date, @finding.first_follow_up_date
    assert_equal @finding.first_follow_up_date, @finding.first_follow_up_date_on_versions
  end

  test 'mark as duplicated' do
    finding     = findings :unanswered_for_level_1_notification
    repeated_of = findings :being_implemented_weakness

    assert_equal 0, finding.repeated_ancestors.size
    assert_equal 0, repeated_of.repeated_children.size
    assert_not_equal repeated_of.origination_date, finding.origination_date
    refute repeated_of.repeated?

    finding.update! repeated_of_id: repeated_of.id

    assert repeated_of.reload.repeated?
    assert finding.reload.repeated_of
    refute finding.rescheduled?
    assert_equal 0, finding.reschedule_count
    assert_equal repeated_of.origination_date, finding.origination_date
    assert_equal 1, finding.repeated_ancestors.size
    assert_equal 1, repeated_of.repeated_children.size
    assert_equal repeated_of, finding.repeated_root

    # After that it can not be destroyed
    assert_no_difference 'Finding.count' do
      finding.destroy
    end

    # Let try to repeat again
    repeated_of = findings :being_implemented_weakness_on_final

    assert_raise RuntimeError do
      finding.update repeated_of_id: repeated_of.id
    end
  end

  test 'undo reiteration' do
    finding                    = findings :unanswered_for_level_1_notification
    repeated_of                = findings :being_implemented_weakness
    repeated_of_original_state = repeated_of.state

    refute repeated_of.repeated?

    finding.update! repeated_of_id: repeated_of.id, reschedule_count: 1

    assert repeated_of.reload.repeated?
    assert finding.reload.repeated_of
    assert finding.rescheduled?
    assert_equal 1, finding.reschedule_count

    finding.undo_reiteration

    refute repeated_of.reload.repeated?
    assert_nil finding.reload.repeated_of
    refute finding.rescheduled?
    assert_equal 0, finding.reschedule_count
    assert_equal repeated_of_original_state, repeated_of.state
  end

  test 'reschedule when mark as duplicated and follow up date differs' do
    finding     = findings :unanswered_for_level_1_notification
    repeated_of = findings :being_implemented_weakness

    assert_equal 0, finding.repeated_ancestors.size
    assert_equal 0, repeated_of.repeated_children.size
    assert_not_equal repeated_of.origination_date, finding.origination_date
    refute repeated_of.repeated?

    finding.update! repeated_of_id: repeated_of.id,
      state: Finding::STATUS[:being_implemented],
      follow_up_date: repeated_of.follow_up_date + 1.day

    assert repeated_of.reload.repeated?
    assert finding.reload.repeated_of
    assert finding.rescheduled?
    assert_equal 1, finding.reschedule_count
    assert_equal repeated_of.origination_date, finding.origination_date
    assert_equal 1, finding.repeated_ancestors.size
    assert_equal 1, repeated_of.repeated_children.size
    assert_equal repeated_of, finding.repeated_root

    finding.update! follow_up_date: repeated_of.follow_up_date

    # Should unmark when follow up date has been "restored"
    refute finding.reload.rescheduled?
    assert_equal 0, finding.reschedule_count
  end

  test 'do nothing on repeat if repeated_of is not included on review' do
    finding     = findings :unanswered_for_level_1_notification
    repeated_of = findings :being_implemented_weakness

    finding.review.finding_review_assignments.clear

    assert_raise RuntimeError do
      finding.update repeated_of_id: repeated_of.id
    end
  end

  test 'follow up pdf' do
    refute File.exist?(@finding.absolute_follow_up_pdf_path)

    assert_nothing_raised do
      @finding.follow_up_pdf organizations(:cirope)
    end

    assert File.exist?(@finding.absolute_follow_up_pdf_path)
    assert (size = File.size(@finding.absolute_follow_up_pdf_path)) > 0

    FileUtils.rm @finding.absolute_follow_up_pdf_path

    assert_nothing_raised do
      @finding.follow_up_pdf organizations(:cirope), brief: true
    end

    assert File.exist?(@finding.absolute_follow_up_pdf_path)
    assert File.size(@finding.absolute_follow_up_pdf_path) > 0
    assert_not_equal size, File.size(@finding.absolute_follow_up_pdf_path)

    FileUtils.rm @finding.absolute_follow_up_pdf_path
  end

  test 'to pdf' do
    refute File.exist?(@finding.absolute_pdf_path)

    assert_nothing_raised do
      @finding.to_pdf organizations(:cirope)
    end

    assert File.exist?(@finding.absolute_pdf_path)
    assert File.size(@finding.absolute_pdf_path) > 0

    FileUtils.rm @finding.absolute_pdf_path
  end

  test 'to csv' do
    csv  = Finding.all.to_csv
    # TODO: change to liberal_parsing: true when 2.3 support is dropped
    rows = CSV.parse csv.sub("\uFEFF", ''), col_sep: ';', force_quotes: true

    assert_equal Finding.count + 1, rows.length
  end

  test 'notify users if they are selected for notification' do
    @finding.users_for_notification = [users(:administrator).id]

    assert_enqueued_emails 1 do
      @finding.save!
    end
  end

  test 'not notify users if is incomplete' do
    finding                        = findings :incomplete_weakness
    finding.users_for_notification = [users(:administrator).id]

    assert_no_enqueued_emails do
      finding.save!
    end
  end

  test 'notify for stale and unconfirmed findings' do
    Current.organization = nil
    # Only if no weekend
    assert Time.zone.today.workday?
    assert_not_equal 0, Finding.unconfirmed_for_notification.size

    review_codes_by_user =
      review_codes_on_findings_by_user :unconfirmed_for_notification

    assert_enqueued_emails 1 do
      Finding.notify_for_unconfirmed_for_notification_findings
    end
  end

  test 'warning users about findings expiration' do
    Current.organization = nil
    # Only if no weekend
    assert Time.zone.today.workday?

    review_codes_by_user = review_codes_on_findings_by_user :next_to_expire

    assert_enqueued_emails 7 do
      Finding.warning_users_about_expiration
    end
  end

  test 'remember users about expired findings' do
    skip if DISABLE_FINDINGS_EXPIRATION_NOTIFICATION

    Current.organization = nil
    review_codes_by_user = review_codes_on_findings_by_user :expired

    assert_enqueued_emails 6 do
      Finding.remember_users_about_expiration
    end
  end

  test 'remember users about unanswered findings' do
    skip if DISABLE_FINDINGS_EXPIRATION_NOTIFICATION

    Current.organization = nil
    review_codes_by_user = review_codes_on_findings_by_user :expired

    Finding.unanswered.update_all notification_level: -1

    assert Finding.unanswered_disregarded.count > 0

    users = Finding.unanswered_disregarded.inject([]) do |u, finding|
      u | finding.users
    end

    assert_enqueued_emails users.size do
      Finding.remember_users_about_unanswered
    end
  end

  test 'mark stale and confirmed findings as unanswered' do
    Current.organization = nil
    # Only if no weekend
    assert Time.zone.today.workday?

    review_codes_by_user = review_codes_on_user_findings_by_user :confirmed_and_stale
    unanswered_count     = Finding.where(state: Finding::STATUS[:unanswered]).count

    assert_enqueued_emails review_codes_by_user.size do
      Finding.mark_as_unanswered_if_necesary
    end

    new_unanswered_count = Finding.where(state: Finding::STATUS[:unanswered]).count

    assert_not_equal unanswered_count, new_unanswered_count
    assert Finding.confirmed_and_stale.empty?
  end

  test 'not mark stale and confirmed findings if has an audited answer' do
    counts = [
      'Finding.confirmed_and_stale.count',
      'Finding.where(state: Finding::STATUS[:unanswered]).count'
    ]

    Current.organization = nil
    # Only if no weekend
    assert Time.zone.today.workday?
    assert Finding.confirmed_and_stale.any?

    Finding.confirmed_and_stale.each do |finding|
      finding.finding_answers.create!(
        answer: 'New answer',
        user:   users(:audited)
      )
    end

    assert_no_difference counts do
      assert_no_enqueued_emails { Finding.mark_as_unanswered_if_necesary }
    end

    assert Finding.confirmed_and_stale.any?
  end

  test 'notify manager if necesary' do
    Current.organization = nil
    # Only if no weekend
    assert Time.zone.today.workday?

    findings_and_users              = unanswered_and_stale_findings_with_users_by_level
    users_by_level_for_notification = findings_and_users[:users_by_level_for_notification]
    finding_ids                     = findings_and_users[:finding_ids]

    # No level 4 notification
    assert_enqueued_emails 3 do
      level_counts = {}

      finding_ids.each do |f_id|
        level_counts[f_id] = Finding.find(f_id).notification_level
      end

      Finding.notify_manager_if_necesary

      finding_ids.each do |f_id|
        assert_equal level_counts[f_id].next, Finding.find(f_id).notification_level
      end
    end
  end

  test 'notify expired follow up' do
    skip unless NOTIFY_EXPIRED_AND_STALE_FOLLOW_UP

    Current.organization = nil
    # Only if no weekend
    assert Time.zone.today.workday?

    finding = findings :being_implemented_weakness

    finding.update! follow_up_date: (1.weeks + 1.day).ago.to_date

    findings_and_users              = expired_findings_with_users_by_level
    users_by_level_for_notification = findings_and_users[:users_by_level_for_notification]
    finding_ids                     = findings_and_users[:finding_ids]


    assert_enqueued_emails 1 do
      level_counts = {}

      finding_ids.each do |f_id|
        level_counts[f_id] = Finding.find(f_id).notification_level
      end

      Finding.notify_expired_and_stale_follow_up

      finding_ids.each do |f_id|
        level = Finding.find(f_id).notification_level

        assert level == level_counts[f_id].next || level == -1
      end
    end
  end

  test 'send findings brief' do
    Current.organization = nil

    # Since default settings prevents this from happening
    assert_no_enqueued_emails do
      Finding.send_brief
    end

    organization         = organizations :cirope
    Current.organization = organization # Since we use list below
    users                = organization.users.list_all_with_pending_findings

    organization.settings.find_by(name: 'brief_period_in_weeks').update! value: '2'

    assert_not_equal 0, users.size

    Timecop.freeze(FINDING_INITIAL_BRIEF_DATE + 2.weeks) do
      assert_enqueued_emails users.size do
        Finding.send_brief
      end
    end

    Timecop.freeze(FINDING_INITIAL_BRIEF_DATE + 1.weeks) do
      assert_no_enqueued_emails do
        Finding.send_brief
      end
    end
  end

  test 'work papers can be added to finding with current close date' do
    Current.user       = users :supervisor
    uneditable_finding = findings :being_implemented_weakness

    assert_difference 'WorkPaper.count' do
      uneditable_finding.update(
        work_papers_attributes: {
          '1_new' => {
            name: 'New post_workpaper name',
            code: 'PTO 20',
            file_model_attributes: {
              file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
            }
          }
        }
      )
    end
  end

  test 'work papers can not be added to finding with expired close date' do
    uneditable_finding       = findings :being_implemented_weakness_on_final
    uneditable_finding.final = true

    assert_no_difference 'WorkPaper.count' do
      assert_raise RuntimeError do
        uneditable_finding.update(
          work_papers_attributes: {
            '1_new' => {
              name: 'New post_workpaper name',
              code: 'PTO 20',
              organization_id: organizations(:cirope).id,
              file_model_attributes: {
                file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
              }
            }
          }
        )
      end
    end
  end

  test 'validate final state change mark all task as finished' do
    Current.user = users :supervisor
    finding      = findings :being_implemented_weakness

    assert_difference 'finding.tasks.count' do
      finding.tasks.create! code: '02', description: 'Test', due_on: Time.zone.today
    end

    assert finding.reload.tasks.all? { |t| !t.finished? }

    assert_no_difference 'Task.finished.count' do
      finding.update! state: Finding::STATUS[:implemented]
    end

    assert_difference 'Task.finished.count', finding.tasks.count do
      finding.update!(
        state:         Finding::STATUS[:implemented_audited],
        solution_date: 1.month.from_now
      )
    end

    assert finding.reload.tasks.all? { |t| t.finished? }
  end

  test 'mark all task as finished when repeated' do
    finding     = findings :unanswered_for_level_1_notification
    repeated_of = findings :being_implemented_weakness

    assert_difference 'repeated_of.tasks.count' do
      repeated_of.tasks.create! code: '01', description: 'Test', due_on: Time.zone.today
    end

    assert repeated_of.reload.tasks.all? { |t| !t.finished? }

    assert_difference 'Task.finished.count', repeated_of.tasks.count do
      finding.update! repeated_of_id: repeated_of.id
    end

    assert repeated_of.reload.tasks.all? { |t| t.finished? }
  end

  test 'sync taggings' do
    skip unless WEAKNESS_TAG_SYNC

    finding      = findings :being_implemented_weakness_on_approved_draft
    Current.user = users :supervisor

    ConclusionFinalReview.list.new(
      review_id: reviews(:review_approved_with_conclusion).id,
      issue_date: Date.today,
      close_date: CONCLUSION_FINAL_REVIEW_EXPIRE_DAYS.business_days.from_now.to_date,
      applied_procedures: 'New applied procedures',
      conclusion: CONCLUSION_OPTIONS.first,
      recipients: 'John Doe',
      sectors: 'Area 51',
      evolution: EVOLUTION_OPTIONS.second,
      evolution_justification: 'Ok',
      main_weaknesses_text: 'Some main weakness X',
      corrective_actions: 'You should do it this way',
      :reference => 'Some reference',
      :observations => 'Some observations',
      :scope => 'Some scope',
      affects_compliance: false
    ).save!

    final_twin = finding.children.take!
    tag = tags :follow_up

    assert final_twin.taggings.where(tag_id: tag.id).empty?

    assert_difference 'Tagging.count', 2 do
      finding.taggings.create! tag_id: tag.id
    end

    assert final_twin.reload.taggings.where(tag_id: tag.id).exists?

    assert_difference 'Tagging.count', -2 do
      finding.reload.taggings.each do |t|
        if t.tag_id == tag.id
          t.mark_for_destruction
        end
      end

      finding.save!
    end

    assert final_twin.reload.taggings.where(tag_id: tag.id).empty?
  end

  test 'unconfirmed for notification scope' do
    assert Finding.unconfirmed_for_notification.any?

    Finding.unconfirmed_for_notification.each do |finding|
      finding.update_column :first_notification_date,
        FINDING_DAYS_FOR_SECOND_NOTIFICATION.next.business_days.ago.to_date
    end

    refute Finding.unconfirmed_for_notification.any?
  end

  test 'next to expire scope' do
    before_expire = FINDING_WARNING_EXPIRE_DAYS.pred.business_days.from_now.to_date
    expire        = FINDING_WARNING_EXPIRE_DAYS.business_days.from_now.to_date

    all_findings_are_in_range = Finding.next_to_expire.all? do |finding|
      finding.follow_up_date.between?(before_expire, expire) ||
        finding.solution_date.between?(before_expire, expire)
    end

    assert all_findings_are_in_range
  end

  test 'expired scope' do
    all_follow_up_dates_are_old = Finding.expired.all? do |finding|
      finding.follow_up_date < Time.zone.today
    end

    assert all_follow_up_dates_are_old
  end

  test 'reset notification level on follow up date change' do
    @finding.update! notification_level: 2

    @finding.update! follow_up_date: Time.zone.today,
                     state:          Finding::STATUS[:being_implemented]

    assert_equal 0, @finding.reload.notification_level
  end

  test 'put state dates on changes' do
    @finding.update! state:          Finding::STATUS[:implemented],
                     follow_up_date: Time.zone.today

    assert_equal Time.zone.today, @finding.reload.implemented_at
    assert_nil @finding.closed_at

    Current.user = users :supervisor

    @finding.update! state:           Finding::STATUS[:implemented_audited],
                     solution_date:   Time.zone.today,
                     skip_work_paper: true

    assert_equal Time.zone.today, @finding.reload.closed_at
  end

  test 'version implemented at' do
    Timecop.travel 2.days.ago do
      @finding.update! state:          Finding::STATUS[:implemented],
                       follow_up_date: Time.zone.today
    end

    assert_equal 2.days.ago.to_date, @finding.version_implemented_at
  end

  test 'version closed at' do
    Current.user = users :supervisor

    Timecop.travel 2.days.ago do
      @finding.update! state:         Finding::STATUS[:expired],
                       solution_date: Time.zone.today
    end

    assert_equal 2.days.ago.to_date, @finding.version_closed_at
  end

  private

    def review_codes_on_findings_by_user method
      review_codes_by_user = {}

      Finding.send(method).each do |finding|
        finding.users.each do |user|
          review_codes_by_user[user] ||= []

          user.notifications.not_confirmed.each do |n|
            assert n.findings.present?

            review_codes_by_user[user] |= n.findings.send(method).map(&:review_code)
          end
        end
      end

      review_codes_by_user
    end

    def review_codes_on_user_findings_by_user method
      review_codes_by_user = {}

      findings = Finding.send(method).reject do |finding|
        finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
      end

      users = findings.inject([]) do |u, finding|
        u | finding.finding_user_assignments.map(&:user)
      end

      users.each do |user|
        findings_by_user = user.findings.send(method).reject do |finding|
          finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
        end

        assert findings_by_user.present?
        review_codes_by_user[user] = findings_by_user.map(&:review_code)
      end

      review_codes_by_user
    end

    def unanswered_and_stale_findings_with_users_by_level
      n                               = 0
      finding_ids                     = []
      users_by_level_for_notification = {1 => [], 2 => [], 3 => [], 4 => []}

      while (findings = Finding.unanswered_and_stale(n += 1)).present?
        findings.each do |finding|
          # Not for president users since it belongs to another organization
          if n != 4
            users = finding.users_for_scaffold_notification(n)
            has_audited_comments = finding.finding_answers.reload.any? do |fa|
              fa.user.can_act_as_audited?
            end

            unless has_audited_comments
              finding_ids << finding.id
              users_by_level_for_notification[n] |= finding.users |
                finding.users_for_scaffold_notification(n)
            end
          end
        end
      end

      {
        users_by_level_for_notification: users_by_level_for_notification,
        finding_ids:                     finding_ids
      }
    end

    def expired_findings_with_users_by_level
      n                               = 0
      finding_ids                     = []
      users_by_level_for_notification = {1 => [], 2 => [], 3 => [], 4 => []}
      deepest_level                   = User.deepest_level

      (1..deepest_level).each do |n|
        findings = Finding.pending_expired_and_stale n

        findings.each do |finding|
          # Not for president users since it belongs to another organization
          if n != 4
            users = finding.users_for_scaffold_notification(n)
            commitment_date = finding.last_commitment_date

            if commitment_date.blank? || commitment_date.past?
              finding_ids << finding.id
              users_by_level_for_notification[n] |= finding.users |
                finding.users_for_scaffold_notification(n)
            end
          end
        end
      end

      {
        users_by_level_for_notification: users_by_level_for_notification,
        finding_ids:                     finding_ids
      }
    end
end
