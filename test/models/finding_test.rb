require 'test_helper'

class FindingTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @finding = findings :unanswered_weakness

    set_organization
  end

  test 'create' do
    state = if USE_SCOPE_CYCLE
              Finding::STATUS[:incomplete]
            else
              Finding::STATUS[:notify]
            end

    assert_difference 'Finding.count' do
      assert_difference 'Tagging.count', 2 do
        @finding.class.list.create!(
          control_objective_item: control_objective_items(:impact_analysis_item_editable),
          review_code: 'O020',
          title: 'Title',
          description: 'New description',
          brief: 'New brief',
          answer: 'New answer',
          audit_comments: 'New audit comments',
          state: state,
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
          manual_risk: true,
          risk_justification: 'Test',
          finding_user_assignments_attributes: {
            new_1: {
              user_id: users(:audited).id, process_owner: true
            },
            new_2: {
              user_id: users(:auditor).id, process_owner: false, responsible_auditor: true
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
    state = if USE_SCOPE_CYCLE
              Finding::STATUS[:incomplete]
            else
              Finding::STATUS[:notify]
            end

    assert_no_difference 'Finding.count' do
      finding = Finding.list.create(
        control_objective_item: control_objective_items(:impact_analysis_item),
        review_code: 'O020',
        title: 'Title',
        description: 'New description',
        brief: 'New brief',
        answer: 'New answer',
        audit_comments: 'New audit comments',
        state: state,
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
        manual_risk: true,
        risk_justification: 'Test',
        finding_user_assignments_attributes: {
          new_1: {
            user_id: users(:audited).id, process_owner: true
          },
          new_2: {
            user_id: users(:auditor).id, process_owner: false, responsible_auditor: true
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
    @finding.brief                     = '   '

    assert @finding.invalid?
    assert_error @finding, :control_objective_item_id, :blank
    assert_error @finding, :review_code, :blank
    assert_error @finding, :review_code, :invalid
    assert_error @finding, :title, :blank
    assert_error @finding, :description, :blank

    if USE_SCOPE_CYCLE
      assert_error @finding, :brief, :blank
    else
      assert @finding.errors[:brief].blank?
    end
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
    skip if HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK

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
    skip if HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK

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
    skip if HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK

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
        state:         Finding::STATUS[:expired],
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
    assert_nil repeated_of.latest_id
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
    assert_equal finding.id, repeated_of.latest_id

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
    assert_equal finding.id, repeated_of.latest_id

    if POSTGRESQL_ADAPTER
      assert_equal [repeated_of.id], finding.parent_ids
      assert_empty repeated_of.parent_ids
    end

    finding.undo_reiteration

    refute repeated_of.reload.repeated?
    assert_nil finding.reload.repeated_of
    assert_nil repeated_of.latest_id
    refute finding.rescheduled?
    assert_equal 0, finding.reschedule_count
    assert_equal repeated_of_original_state, repeated_of.state

    if POSTGRESQL_ADAPTER
      assert_empty finding.parent_ids
      assert_empty repeated_of.parent_ids
    end
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

    count_reschedule = USE_SCOPE_CYCLE ? 3 : 4

    assert_equal count_reschedule, finding.reschedule_count
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
    Current.organization = organizations :cirope
    # Only if no weekend
    assert Time.zone.today.workday?

    before_expire = Array(7.business_days.from_now.to_date)

    review_codes_by_user = review_codes_on_findings_by_user :expires_on, args: before_expire

    assert_enqueued_emails 7 do
      Finding.warning_users_about_expiration
    end
  ensure
    Current.organization = nil
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

    organization         = organizations :cirope
    Current.organization = organization
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

    unless HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK
      assert_no_difference 'Task.finished.count' do
        finding.update! state: Finding::STATUS[:implemented]
      end
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

    final_twin = finding.reload.children.take!
    tag        = tags :follow_up

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
    Current.organization = organizations :cirope

    before_expire = 7.pred.business_days.from_now.to_date
    expire        = 7.business_days.from_now.to_date

    all_findings_are_in_range = Finding.expires_on([before_expire]).all? do |finding|
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
    skip if HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK

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
    skip if HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK

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

  test 'require commitment support' do
    skip unless %(true).include? FINDING_ANSWER_COMMITMENT_SUPPORT

    finding = findings :being_implemented_weakness

    assert finding.require_commitment_support?(finding.follow_up_date + 1.day)
    refute finding.require_commitment_support?(finding.follow_up_date)
  end

  test 'not commitment date required level when dont have first follow up date' do
    assert_nil (findings :unconfirmed_for_notification_weakness).commitment_date_required_level
  end

  test 'not commitment date required level when dont have finding answers' do
    assert_nil (findings :being_implemented_weakness).commitment_date_required_level
  end

  test 'commitment date required level by comittee when high risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    assert_equal :committee,
                 finding.commitment_date_required_level(one_day_later_of_required_level_if_is_end_of_month(finding, :high, :ceo))
  end

  test 'commitment date required level by comittee when high risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_beginning_of_month finding

    assert_equal :committee,
                 finding.commitment_date_required_level(one_day_later_of_required_level(finding, :high, :ceo))
  end

  test 'commitment date required level by comittee when high risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :high, :ceo)

    assert_equal :committee, finding.commitment_date_required_level
  end

  test 'commitment date required level by comittee when high risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_beginning_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level(finding, :high, :ceo)

    assert_equal :committee, finding.commitment_date_required_level
  end

  test 'commitment date required level by ceo when high risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    assert_equal :ceo,
                 finding.commitment_date_required_level(one_day_later_of_required_level_if_is_end_of_month(finding, :high, :management))
  end

  test 'commitment date required level by ceo when high risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_beginning_of_month finding

    assert_equal :ceo,
                 finding.commitment_date_required_level(one_day_later_of_required_level(finding, :high, :management))
  end

  test 'commitment date required level by ceo when high risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :high, :management)

    assert_equal :ceo, finding.commitment_date_required_level
  end

  test 'commitment date required level by ceo when high risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_beginning_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level(finding, :high, :management)

    assert_equal :ceo, finding.commitment_date_required_level
  end

  test 'commitment date required level by management when high risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    assert_equal :management,
                 finding.commitment_date_required_level(one_day_later_of_required_level_if_is_end_of_month(finding, :high, :manager))
  end

  test 'commitment date required level by management when high risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_beginning_of_month finding

    assert_equal :management,
                 finding.commitment_date_required_level(one_day_later_of_required_level(finding, :high, :manager))
  end

  test 'commitment date required level by management when high risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :high, :manager)

    assert_equal :management, finding.commitment_date_required_level
  end

  test 'commitment date required level by management when high risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_beginning_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :high, :manager)

    assert_equal :management, finding.commitment_date_required_level
  end

  test 'commitment date required level by manager when high risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    commitment_date = (finding.first_follow_up_date +
                       Finding::COMMITMENT_REQUIREMENTS[:high].invert[:manager].months).at_end_of_month

    assert_equal :manager, finding.commitment_date_required_level(commitment_date)
  end

  test 'commitment date required level by manager when high risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_beginning_of_month finding

    commitment_date = finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:high].invert[:manager].months

    assert_equal :manager, finding.commitment_date_required_level(commitment_date)
  end

  test 'commitment date required level by manager when high risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    commitment_date = (finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:high].invert[:manager].months).at_end_of_month

    create_finding_answer_with_commitment_date finding, commitment_date

    assert_equal :manager, finding.commitment_date_required_level
  end

  test 'commitment date required level by manager when high risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_beginning_of_month finding

    commitment_date = finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:high].invert[:manager].months

    create_finding_answer_with_commitment_date finding, commitment_date

    assert_equal :manager, finding.commitment_date_required_level
  end

  test 'commitment date required level by comittee when medium risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_end_of_month finding

    assert_equal :committee,
                 finding.commitment_date_required_level(one_day_later_of_required_level_if_is_end_of_month(finding, :medium, :ceo))
  end

  test 'commitment date required level by comittee when medium risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_beginning_of_month finding

    assert_equal :committee,
                 finding.commitment_date_required_level(one_day_later_of_required_level(finding, :medium, :ceo))
  end

  test 'commitment date required level by comittee when medium risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :medium, :ceo)

    assert_equal :committee, finding.commitment_date_required_level
  end

  test 'commitment date required level by comittee when medium risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_beginning_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level(finding, :medium, :ceo)

    assert_equal :committee, finding.commitment_date_required_level
  end

  test 'commitment date required level by ceo when medium risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_end_of_month finding

    assert_equal :ceo,
                 finding.commitment_date_required_level(one_day_later_of_required_level_if_is_end_of_month(finding, :medium, :management))
  end

  test 'commitment date required level by ceo when medium risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_beginning_of_month finding

    assert_equal :ceo,
                 finding.commitment_date_required_level(one_day_later_of_required_level(finding, :medium, :management))
  end

  test 'commitment date required level by ceo when medium risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :medium, :management)

    assert_equal :ceo, finding.commitment_date_required_level
  end

  test 'commitment date required level by ceo when medium risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_beginning_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level(finding, :medium, :management)

    assert_equal :ceo, finding.commitment_date_required_level
  end

  test 'commitment date required level by management when medium risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_end_of_month finding

    assert_equal :management,
                 finding.commitment_date_required_level(one_day_later_of_required_level_if_is_end_of_month(finding, :medium, :manager))
  end

  test 'commitment date required level by management when medium risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_beginning_of_month finding

    assert_equal :management,
                 finding.commitment_date_required_level(one_day_later_of_required_level(finding, :medium, :manager))
  end

  test 'commitment date required level by management when medium risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :medium, :manager)

    assert_equal :management, finding.commitment_date_required_level
  end

  test 'commitment date required level by management when medium risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_beginning_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level(finding, :medium, :manager)

    assert_equal :management, finding.commitment_date_required_level
  end

  test 'commitment date required level by manager when medium risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_end_of_month finding

    commitment_date = (finding.first_follow_up_date +
                       Finding::COMMITMENT_REQUIREMENTS[:medium].invert[:manager].months).at_end_of_month

    assert_equal :manager, finding.commitment_date_required_level(commitment_date)
  end

  test 'commitment date required level by manager when medium risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_beginning_of_month finding

    commitment_date = finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:medium].invert[:manager].months

    assert_equal :manager, finding.commitment_date_required_level(commitment_date)
  end

  test 'commitment date required level by manager when medium risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_end_of_month finding

    commitment_date = (finding.first_follow_up_date +
                       Finding::COMMITMENT_REQUIREMENTS[:medium].invert[:manager].months).at_end_of_month

    create_finding_answer_with_commitment_date finding, commitment_date

    assert_equal :manager, finding.commitment_date_required_level
  end

  test 'commitment date required level by manager when medium risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:medium]

    set_first_follow_update_at_beginning_of_month finding

    commitment_date = finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:medium].invert[:manager].months

    create_finding_answer_with_commitment_date finding, commitment_date

    assert_equal :manager, finding.commitment_date_required_level
  end

  test 'commitment date required level by management when low risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:low]

    set_first_follow_update_at_end_of_month finding

    assert_equal :management,
                 finding.commitment_date_required_level(one_day_later_of_required_level_if_is_end_of_month(finding, :low, :manager))
  end

  test 'commitment date required level by management when low risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:low]

    set_first_follow_update_at_beginning_of_month finding

    assert_equal :management,
                 finding.commitment_date_required_level(one_day_later_of_required_level(finding, :low, :manager))
  end

  test 'commitment date required level by management when low risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:low]

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :low, :manager)

    assert_equal :management, finding.commitment_date_required_level
  end

  test 'commitment date required level by management when low risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:low]

    set_first_follow_update_at_beginning_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level(finding, :low, :manager)

    assert_equal :management, finding.commitment_date_required_level
  end

  test 'commitment date required level by manager when low risk and first follow up date at end of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:low]

    set_first_follow_update_at_end_of_month finding

    commitment_date = (finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:low].invert[:manager].months).at_end_of_month

    assert_equal :manager, finding.commitment_date_required_level(commitment_date)
  end

  test 'commitment date required level by manager when low risk and first follow up date at beginning of month' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:low]

    set_first_follow_update_at_beginning_of_month finding

    commitment_date = finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:low].invert[:manager].months

    assert_equal :manager, finding.commitment_date_required_level(commitment_date)
  end

  test 'commitment date required level by manager when low risk, first follow up date at end of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:low]

    set_first_follow_update_at_end_of_month finding

    commitment_date = (finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:low].invert[:manager].months).at_end_of_month

    create_finding_answer_with_commitment_date finding, commitment_date

    assert_equal :manager, finding.commitment_date_required_level
  end

  test 'commitment date required level by manager when low risk, first follow up date at beginning of month and have last commitment date' do
    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:low]

    set_first_follow_update_at_beginning_of_month finding

    commitment_date = finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:low].invert[:manager].months

    create_finding_answer_with_commitment_date finding, commitment_date

    assert_equal :manager, finding.commitment_date_required_level
  end

  test 'commitment date required level by committee when none risk' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:none]

    assert_equal :committee,
                 finding.commitment_date_required_level(finding.first_follow_up_date)

    assert_equal :committee,
                 finding.commitment_date_required_level(finding.first_follow_up_date + 1000.months)
  end

  test 'commitment date required level by committee when none risk and have commitment date' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :being_implemented_weakness

    finding.update_column :risk, Finding.risks[:none]

    create_finding_answer_with_commitment_date finding, finding.first_follow_up_date

    assert_equal :committee, finding.commitment_date_required_level

    create_finding_answer_with_commitment_date finding, (finding.first_follow_up_date + 1000.months)

    assert_equal :committee, finding.commitment_date_required_level
  end

  test 'commitment date required level text by comittee when pass date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    assert_equal I18n.t('finding.commitment_date_required_level.committee'),
                 finding.commitment_date_required_level_text(one_day_later_of_required_level_if_is_end_of_month(finding, :high, :ceo))
  end

  test 'commitment date required level text by comittee when have commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :high, :ceo)

    assert_equal I18n.t('finding.commitment_date_required_level.committee'),
                 finding.commitment_date_required_level_text
  end

  test 'commitment date required level text by ceo when pass date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    assert_equal I18n.t('finding.commitment_date_required_level.ceo'),
                 finding.commitment_date_required_level_text(one_day_later_of_required_level_if_is_end_of_month(finding, :high, :management))
  end

  test 'commitment date required level text by ceo when have commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :high, :management)

    assert_equal I18n.t('finding.commitment_date_required_level.ceo'),
                 finding.commitment_date_required_level_text
  end

  test 'commitment date required level text by management when pass date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    assert_equal I18n.t('finding.commitment_date_required_level.management'),
                 finding.commitment_date_required_level_text(one_day_later_of_required_level_if_is_end_of_month(finding, :high, :manager))
  end

  test 'commitment date required level text by management when have commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    create_finding_answer_with_commitment_date finding,
                                               one_day_later_of_required_level_if_is_end_of_month(finding, :high, :manager)

    assert_equal I18n.t('finding.commitment_date_required_level.management'),
                 finding.commitment_date_required_level_text
  end

  test 'commitment date required level text by manager when pass date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    commitment_date = (finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:high].invert[:manager].months).at_end_of_month

    assert_equal I18n.t('finding.commitment_date_required_level.manager'),
                 finding.commitment_date_required_level_text(commitment_date)
  end

  test 'commitment date required level text by manager when have commitment date' do
    finding = findings :being_implemented_weakness

    set_first_follow_update_at_end_of_month finding

    commitment_date = (finding.first_follow_up_date +
                      Finding::COMMITMENT_REQUIREMENTS[:high].invert[:manager].months).at_end_of_month

    create_finding_answer_with_commitment_date finding, commitment_date

    assert_equal I18n.t('finding.commitment_date_required_level.manager'),
                 finding.commitment_date_required_level_text
  end

  test 'get show commitment support' do
    assert_equal %w(true weak).include?(FINDING_ANSWER_COMMITMENT_SUPPORT),
                 Finding.show_commitment_support?
  end

  test 'commitment limit date message' do
    skip if COMMITMENT_DATE_LIMITS.blank?

    @finding.risk           = Finding.risks[:high]
    @finding.follow_up_date = Time.zone.today
    commitment_date         = Time.zone.today + 13.months
    comment_six_months      = COMMITMENT_DATE_LIMITS['reschedule']['default']['6.months']

    with_follow_up_date     = @finding.commitment_date_message_for commitment_date

    assert_equal with_follow_up_date, comment_six_months

    comment_one_year        = COMMITMENT_DATE_LIMITS['first_date']['high']['1.year']
    @finding.follow_up_date = nil
    without_follow_up_date  = @finding.commitment_date_message_for commitment_date

    assert_equal without_follow_up_date, comment_one_year

    @finding.risk           = Finding.risks[:low]
    @finding.follow_up_date = nil
    commitment_date         = Time.zone.today + 13.months

    without_message  = @finding.commitment_date_message_for commitment_date

    assert_nil without_message
  end

  test 'check auto risk when change to automatic' do
    skip unless USE_SCOPE_CYCLE

    @finding.risk = Finding.risks[:high]

    assert @finding.valid?
    assert_equal Finding.risks[:high], @finding.risk

    @finding.manual_risk = false
    @finding.probability        = Finding.probabilities[:rare]
    @finding.impact_risk        = Finding.impact_risks[:moderate]

    assert @finding.valid?
    assert_equal Finding.risks[:low], @finding.risk

    @finding.probability        = Finding.probabilities[:almost_certain]
    @finding.impact_risk        = Finding.impact_risks[:critical]

    assert @finding.valid?
    assert_equal Finding.risks[:high], @finding.risk

    @finding.probability = Finding.probabilities[:possible]
    @finding.impact_risk = Finding.impact_risks[:moderate]

    assert @finding.valid?
    assert_equal Finding.risks[:medium], @finding.risk
  end

  test 'automatic issue based state' do
    skip unless USE_SCOPE_CYCLE && SHOW_WEAKNESS_PROGRESS

    @finding.issues.build customer: 'Some customer'

    assert @finding.valid?, @finding.errors.full_messages.to_sentence
    assert @finding.awaiting?

    Current.user = users :supervisor

    @finding.issues.all? { |issue| issue.close_date = Time.zone.today }

    @finding.follow_up_date  = Time.zone.today
    @finding.skip_work_paper = true

    assert @finding.valid?
    assert @finding.implemented_audited?
    assert_equal @finding.issues.map(&:close_date).last, @finding.solution_date

    @finding.issues.create! customer: 'Another customer'

    @finding.solution_date = nil

    assert @finding.valid?, @finding.errors.full_messages
    assert @finding.being_implemented?
  ensure
    Current.user = nil
  end

  test 'issues amount' do
    @finding.issues.create!(customer: 'Some customer', amount: 10)
    @finding.issues.create!(customer: 'Some customer dup', amount: 23)

    assert_equal @finding.issues_amount, 33
  end

  test 'get amount by impact' do
    amount = 30844081

    @finding.issues.create!(customer: 'Some customer', amount: amount)

    amount_by_impact = @finding.amount_by_impact

    result = amount_by_impact.reverse_each.to_h.detect { |id, value| amount >= value }

    assert_equal result.first,  @finding.impact_risk_value
  end

  test 'probability risk previuos' do
    Current.organization = organizations :cirope
    Current.user         = users :auditor
    repeatability_in_file = 1

    assert_equal Finding.probability_risk_previous(@finding.review), 0

    @finding.weakness_template = weakness_templates :security

    assert @finding.valid?

    probability_risk_previous_amount = Finding.list.probability_risk_previous @finding.review, @finding.weakness_template

    assert_equal probability_risk_previous_amount, repeatability_in_file

    weakness_previous = @finding.review.previous.weaknesses.first

    weakness_previous.update_column :weakness_template_id, weakness_templates(:security).id

    probability_risk_previous_amount = Finding.probability_risk_previous @finding.review, @finding.weakness_template

    assert_equal probability_risk_previous_amount, repeatability_in_file + 1

  ensure
    Current.organization = nil
    Current.user         = nil
  end

  test 'notify action not found when subject have no finding_id - pop3' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'pop3'

    supervisor = users :supervisor
    body       = 'Reply On Tuesday wrote: Another reply'

    Finding.receive_mail(new_email_pop3(supervisor.email, 'subject without id', body))

    assert_enqueued_emails 1
    assert_enqueued_email_with NotifierMailer, :notify_action_not_found, args: [[supervisor.email], "Reply "]
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'notify action not found when email does not belong to any user - pop3' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'pop3'

    finding = findings :confirmed_oportunity

    body = 'Reply On Tuesday wrote: Another reply'

    Finding.receive_mail(new_email_pop3('nouser@nouser.com', "[##{finding.id}]", body))

    assert_enqueued_emails 1
    assert_enqueued_email_with NotifierMailer, :notify_action_not_found, args: [['nouser@nouser.com'], "Reply "]
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'notify action not found when auditee is not related - pop3' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'pop3'

    finding = findings :confirmed_oportunity
    audited = users :audited_second
    body    = 'Reply On Tuesday wrote: Another reply'

    Finding.receive_mail(new_email_pop3(audited.email, "[##{finding.id}]", body))

    assert_enqueued_emails 1
    assert_enqueued_email_with NotifierMailer, :notify_action_not_found, args: [[audited.email], "Reply "]
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'add finding answer when auditee is related - pop3' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'pop3'

    finding = findings :confirmed_oportunity
    audited = users :audited
    body    = 'Reply On Tuesday wrote: Another reply'

    assert_difference 'finding.finding_answers.count' do
      Finding.receive_mail(new_email_pop3(audited.email, "[##{finding.id}]", body))
    end

    assert_equal finding.finding_answers.last.user, audited
    assert_equal finding.finding_answers.last.answer, 'Reply '
    assert finding.finding_answers.last.imported
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'add finding answer to finding as supervisor - pop3' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'pop3'

    finding    = findings :confirmed_oportunity
    supervisor = users :supervisor
    body       = 'Reply On Tuesday wrote: Another reply'

    assert_difference 'finding.finding_answers.count' do
      Finding.receive_mail(new_email_pop3(supervisor.email, "[##{finding.id}]", body))
    end

    assert_equal finding.finding_answers.last.user, supervisor
    assert_equal finding.finding_answers.last.answer, 'Reply '
    assert finding.finding_answers.last.imported
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'notify action not found when subject have no finding_id - mgraph' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'mgraph'

    supervisor = users :supervisor
    body       = 'Reply On Tuesday wrote: Another reply'

    Finding.receive_mail(new_email_mgraph('id test', supervisor.email, 'subject without id', body))

    assert_enqueued_emails 1
    assert_enqueued_email_with NotifierMailer, :notify_action_not_found, args: [[supervisor.email], "Reply "]
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'notify action not found when email does not belong to any user - mgraph' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'mgraph'

    finding = findings :confirmed_oportunity

    body = 'Reply On Tuesday wrote: Another reply'

    Finding.receive_mail(new_email_mgraph('id test', 'nouser@nouser.com', "[##{finding.id}]", body))

    assert_enqueued_emails 1
    assert_enqueued_email_with NotifierMailer, :notify_action_not_found, args: [['nouser@nouser.com'], 'Reply ']
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'notify action not found when auditee is not related - mgraph' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'mgraph'

    finding = findings :confirmed_oportunity
    audited = users :audited_second
    body    = 'Reply On Tuesday wrote: Another reply'

    Finding.receive_mail(new_email_mgraph('id test', audited.email, "[##{finding.id}]", body))

    assert_enqueued_emails 1
    assert_enqueued_email_with NotifierMailer, :notify_action_not_found, args: [[audited.email], 'Reply ']
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'add finding answer when auditee is related - mgraph' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'mgraph'

    finding = findings :confirmed_oportunity
    audited = users :audited
    body    = 'Reply On Tuesday wrote: Another reply'

    assert_difference 'finding.finding_answers.count' do
      Finding.receive_mail(new_email_mgraph('id test', audited.email, "[##{finding.id}]", body))
    end

    assert_equal finding.finding_answers.last.user, audited
    assert_equal finding.finding_answers.last.answer, 'Reply '
    assert finding.finding_answers.last.imported
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'add finding answer to finding as supervisor - mgraph' do
    old_regex                = ENV['REGEX_REPLY_EMAIL']
    ENV['REGEX_REPLY_EMAIL'] = 'On .*wrote:'
    old_email_method         = ENV['EMAIL_METHOD']
    ENV['EMAIL_METHOD']      = 'mgraph'

    finding    = findings :confirmed_oportunity
    supervisor = users :supervisor
    body       = 'Reply On Tuesday wrote: Another reply'

    assert_difference 'finding.finding_answers.count' do
      Finding.receive_mail(new_email_mgraph('id test', supervisor.email, "[##{finding.id}]", body))
    end

    assert_equal finding.finding_answers.last.user, supervisor
    assert_equal finding.finding_answers.last.answer, 'Reply '
    assert finding.finding_answers.last.imported
  ensure
    ENV['REGEX_REPLY_EMAIL'] = old_regex
    ENV['EMAIL_METHOD']      = old_email_method
  end

  test 'valid with same review code when repeated' do
    @finding.repeated_of = findings(:unconfirmed_weakness)
    @finding.review_code = findings(:unconfirmed_weakness).review_code

    assert @finding.valid?
  end

  test 'should be invalid because has extension when has state excluded from states allowed' do
    skip unless USE_SCOPE_CYCLE

    finding           = findings :incomplete_weakness
    finding.extension = true

    refute finding.valid?
    assert_error finding,
                 :extension,
                 :must_have_state_that_allows_extension,
                 extension: Finding.human_attribute_name(:extension),
                 states: "#{I18n.t('findings.state.being_implemented')} o #{I18n.t('findings.state.awaiting')}"
  end

  test 'should be invalid when is being implemented and has final review but extension_was is false' do
    skip unless USE_SCOPE_CYCLE

    finding           = findings :being_implemented_weakness
    finding.extension = true

    refute finding.valid?
    assert_error finding,
                 :extension,
                 :cant_have_extension_when_didnt_have_extension,
                 extension: Finding.human_attribute_name(:extension),
                 states: "#{I18n.t('findings.state.being_implemented')} o #{I18n.t('findings.state.awaiting')}"
  end

  test 'should be invalid when is awaiting and has final review but extension_was is false' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :being_implemented_weakness
    finding.state = Finding::STATUS[:awaiting]
    finding.extension = true

    refute finding.valid?
    assert_error finding,
                 :extension,
                 :cant_have_extension_when_didnt_have_extension,
                 extension: Finding.human_attribute_name(:extension),
                 states: "#{I18n.t('findings.state.being_implemented')} o #{I18n.t('findings.state.awaiting')}"
  end

  test 'should be valid when is being implemented and has final review and extension_was is true' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :being_implemented_weakness

    finding.update_attribute :extension, true

    finding.extension = true

    assert finding.valid?
  end

  test 'should be valid when is awaiting and has final review and extension_was is true' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :being_implemented_weakness

    finding.update_attribute :extension, true

    finding.state     = Finding::STATUS[:awaiting]
    finding.extension = true

    assert finding.valid?
  end

  test 'should be valid when is being implemented and dont has final review' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :incomplete_weakness

    finding.update_attribute :extension, true

    finding.state          = Finding::STATUS[:being_implemented]
    finding.follow_up_date = Date.today.to_date.to_s(:db)
    finding.extension      = true

    assert finding.valid?
  end

  test 'should be valid when is awaiting and dont has final review' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :incomplete_weakness

    finding.update_attribute :extension, true

    finding.state          = Finding::STATUS[:awaiting]
    finding.follow_up_date = Date.today.to_date.to_s(:db)
    finding.extension      = true

    assert finding.valid?
  end

  test 'calculate reschedule' do
    finding = findings :being_implemented_weakness

    expected_reschedules = USE_SCOPE_CYCLE ? 2 : 3

    assert_equal expected_reschedules, finding.calculate_reschedule_count

    finding.follow_up_date = (7.business_days.from_now.to_date + 2.days).to_s(:db)

    assert_equal expected_reschedules + 1, finding.calculate_reschedule_count

    finding.save!

    finding.follow_up_date = (7.business_days.from_now.to_date + 1.days).to_s(:db)

    assert_equal expected_reschedules + 1, finding.calculate_reschedule_count

    finding.save!

    finding.follow_up_date = (7.business_days.from_now.to_date + 4.days).to_s(:db)

    assert_equal expected_reschedules + 2, finding.calculate_reschedule_count

    if USE_SCOPE_CYCLE
      finding.save!

      finding.state = Finding::STATUS[:awaiting]
      finding.follow_up_date = (7.business_days.from_now.to_date + 6.days).to_s(:db)

      assert_equal expected_reschedules + 3, finding.calculate_reschedule_count

      finding.save!

      finding.follow_up_date = (7777777.business_days.from_now.to_date + 5.days).to_s(:db)

      assert_equal expected_reschedules + 3, finding.calculate_reschedule_count
    end
  end

  test 'should return not reschedule' do
    skip unless USE_SCOPE_CYCLE

    finding = findings :being_implemented_weakness

    finding.update_attribute('extension', true)

    finding.versions.each do |v|
      v.object['extension'] = true

      v.save
    end

    finding.extension      = false
    finding.follow_up_date = (7.business_days.from_now.to_date + 2.days).to_s(:db)
    reschedules            = finding.calculate_reschedule_count

    assert reschedules.zero?

    finding.extension = true
    reschedules       = finding.calculate_reschedule_count

    assert reschedules.zero?
  end

  test 'store follow_up_date_last_changed when change' do
    finding                = findings :being_implemented_weakness
    finding.follow_up_date = (7.business_days.from_now.to_date + 2.days).to_s(:db)

    finding.save!

    assert_equal finding.follow_up_date_last_changed, Time.zone.today
  end

  test 'store follow_up_date_last_changed when change to nil' do
    finding                = findings :incomplete_weakness
    finding.follow_up_date = (7.business_days.from_now.to_date + 2.days).to_s(:db)

    finding.save!

    finding.follow_up_date = nil

    finding.save!

    assert_equal finding.follow_up_date_last_changed, Time.zone.today
  end

  test 'store follow_up_date_last_changed when change from nil' do
    finding                = findings :incomplete_weakness
    finding.follow_up_date = (7.business_days.from_now.to_date + 2.days).to_s(:db)

    finding.save!

    assert_equal finding.follow_up_date_last_changed, Time.zone.today
  end

  test 'should return follow_up_date_last_changed when in last version change follow_up_date' do
    finding = findings :being_implemented_weakness

    follow_up_date_last_changed_on_versions = finding.follow_up_date_last_changed_on_versions

    assert_equal follow_up_date_last_changed_on_versions, I18n.l(finding.updated_at, format: :minimal)
  end

  test 'should return created_at when dont have changes from creation in follow_up_date' do
    finding = findings :being_implemented_weakness_on_draft

    finding.description = 'test'

    finding.save!

    follow_up_date_last_changed_on_versions = finding.follow_up_date_last_changed_on_versions

    assert_equal follow_up_date_last_changed_on_versions, I18n.l(finding.created_at, format: :minimal)
  end

  test 'should return nil when never have follow_up_date' do
    finding = findings :unconfirmed_for_notification_weakness

    finding.description = 'test'

    finding.save!

    assert_nil finding.follow_up_date_last_changed_on_versions
  end

  test 'should return follow_up_date_last_changed when in past didnt have' do
    finding                = findings :incomplete_weakness
    finding.follow_up_date = (7.business_days.from_now.to_date + 2.days).to_s(:db)

    finding.save!

    assert_equal finding.follow_up_date_last_changed_on_versions, I18n.l(finding.updated_at, format: :minimal)
  end

  test 'should return follow_up_date when dont have follow_up_date but in past have' do
    finding                = findings :incomplete_weakness
    finding.follow_up_date = (7.business_days.from_now.to_date + 2.days).to_s(:db)

    finding.save!

    follow_up_date_last_changed_expected = finding.updated_at
    finding.follow_up_date               = nil

    finding.save!

    assert_equal finding.follow_up_date_last_changed_on_versions, I18n.l(follow_up_date_last_changed_expected, format: :minimal)
  end

  test 'should notify findings with follow_up_date_last_changed greater than 90 days' do
    skip if HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK

    finding                             = findings :being_implemented_weakness
    finding.state                       = Finding::STATUS[:implemented]
    finding.follow_up_date_last_changed = Time.zone.today - 91.days

    finding.save!

    assert_enqueued_emails 1 do
      Finding.notify_implemented_findings_with_follow_up_date_last_changed_greater_than_90_days
    end
  end

  test 'should notify not findings with follow_up_date_last_changed greater than 90 days' do
    skip if HIDE_FINDING_IMPLEMENTED_AND_ASSUMED_RISK

    finding                             = findings :being_implemented_weakness
    finding.state                       = Finding::STATUS[:implemented]
    finding.follow_up_date_last_changed = Time.zone.today - 90.days

    finding.save!

    assert_enqueued_emails 0 do
      Finding.notify_implemented_findings_with_follow_up_date_last_changed_greater_than_90_days
    end
  end

  test 'should return suggestion to add days follow up date depending on the risk' do
    expected = {
      0 => 180,
      1 => 365,
      2 => 270,
      3 => 180
    }

    assert_equal Finding.suggestion_to_add_days_follow_up_date_depending_on_the_risk,
                 expected
  end

  test 'should return states that suggest follow up date' do
    assert_equal Finding.states_that_suggest_follow_up_date,
                 [Finding::STATUS[:being_implemented], Finding::STATUS[:awaiting]]
  end

  test 'should return states that allow extension' do
    assert_equal Finding.states_that_allow_extension,
                 [Finding::STATUS[:being_implemented], Finding::STATUS[:awaiting]]
  end

  test 'should return next task expiration when have tasks in progress' do
    finding              = findings :being_implemented_weakness
    next_task_expiration = finding.tasks
                                  .where(status: Task.statuses['in_progress'],
                                         due_on: Date.today..)
                                  .first
                                  .due_on

    assert_equal finding.next_task_expiration, next_task_expiration
  end

  test 'should return next task expiration when have tasks pending' do
    finding = findings :being_implemented_weakness
    task    = tasks :setup_all_things

    task.update! status: Task.statuses['pending']

    next_task_expiration = finding.tasks
                                  .where(status: Task.statuses['pending'],
                                         due_on: Date.today..)
                                  .first
                                  .due_on

    assert_equal finding.next_task_expiration, next_task_expiration
  end

  test 'should not return next task expiration when all tasks are finished' do
    finding = findings :being_implemented_weakness
    task    = tasks :setup_all_things

    task.update! status: Task.statuses['finished']

    assert_nil finding.next_task_expiration
  end

  private

    def new_email_pop3 from, subject, body
      mail = create_mail from, subject

      mail.text_part = Mail::Part.new do
        body body
      end

      mail.html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body          body
      end

      mail
    end

    def create_mail from, subject
      Mail.new do
        from    from
        to      'support@postman.com'
        subject subject
      end
    end

    def new_email_mgraph id, from, subject, body
      OpenStruct.new id: id,
                     subject: subject,
                     from: [from],
                     body: body
    end

    def review_codes_on_findings_by_user method, args: nil
      review_codes_by_user = {}
      Current.organization = organizations :cirope
      findings             = if args.present?
                               Finding.list.send(method, args)
                             else
                               Finding.send(method)
                             end

      findings.each do |finding|
        finding.users.each do |user|
          review_codes_by_user[user] ||= []

          user.notifications.not_confirmed.each do |n|
            assert n.findings.present?

            review_codes_by_user[user] |= if args.present?
                                            n.findings.send(method, args)
                                          else
                                            n.findings.send(method)
                                          end.map(&:review_code)
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

    def set_first_follow_update_at_end_of_month finding
      finding.update_column :first_follow_up_date, finding.first_follow_up_date.at_end_of_month
    end

    def set_first_follow_update_at_beginning_of_month finding
      finding.update_column :first_follow_up_date, finding.first_follow_up_date.beginning_of_month
    end

    def create_finding_answer_with_commitment_date finding, commitment_date
      finding.finding_answers
             .build(
               answer:          'New answer',
               user:            users(:audited),
               commitment_date: commitment_date,
               notify_users:    false)
             .save validate: false
    end

    def one_day_later_of_required_level_if_is_end_of_month finding, risk, previous_level
      (
        finding.first_follow_up_date +
        Finding::COMMITMENT_REQUIREMENTS[risk].invert[previous_level].months +
        1.month
      ).beginning_of_month
    end

    def one_day_later_of_required_level finding, risk, previous_level
      finding.first_follow_up_date +
      Finding::COMMITMENT_REQUIREMENTS[risk].invert[previous_level].months +
      1.days
    end
end
