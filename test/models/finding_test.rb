require 'test_helper'

class FindingTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @finding = findings :unanswered_weakness

    set_organization
  end

  test 'create' do
    assert_difference 'Finding.count' do
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
        operational_risk: 'internal fraud',
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
        }
      )
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
        operational_risk: 'internal fraud',
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
    finding                = findings :unanswered_weakness
    finding.follow_up_date = Time.zone.today
    finding.solution_date  = Time.zone.tomorrow

    assert finding.invalid?
    assert_error finding, :follow_up_date, :must_be_blank
    assert_error finding, :solution_date, :must_be_blank
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
    Finding.current_user  = users :auditor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = 1.month.from_now

    assert finding.invalid?
    assert_error finding, :state, :must_be_done_by_proper_role

    Finding.current_user  = users :supervisor

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

    Finding.current_user = users :supervisor

    assert_difference '@finding.status_change_history.size' do
      @finding.update!(
        state:         Finding::STATUS[:assumed_risk],
        solution_date: Date.today
      )
    end

    Finding.current_user = nil
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
        days_to_add -= 1 unless [0, 6].include?(first_notification_date.wday)
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

    finding.update! repeated_of_id: repeated_of.id

    assert repeated_of.reload.repeated?
    assert finding.reload.repeated_of

    finding.undo_reiteration

    refute repeated_of.reload.repeated?
    assert_nil finding.reload.repeated_of
    assert_equal repeated_of_original_state, repeated_of.state
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
    assert File.size(@finding.absolute_follow_up_pdf_path) > 0

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
    rows = CSV.parse csv, col_sep: ';'

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
    Organization.current_id = nil
    # Only if no weekend
    assert_not_includes [0, 6], Date.today.wday
    assert_not_equal 0, Finding.unconfirmed_for_notification.size

    review_codes_by_user =
      review_codes_on_findings_by_user :unconfirmed_for_notification

    assert_enqueued_emails 1 do
      Finding.notify_for_unconfirmed_for_notification_findings
    end
  end

  test 'warning users about findings expiration' do
    Organization.current_id = nil
    # Only if no weekend
    assert_not_includes [0, 6], Date.today.wday

    review_codes_by_user = review_codes_on_findings_by_user :next_to_expire

    assert_enqueued_emails 7 do
      Finding.warning_users_about_expiration
    end
  end

  test 'remember users about expired findings' do
    skip if DISABLE_FINDINGS_EXPIRATION_NOTIFICATION

    Organization.current_id = nil
    review_codes_by_user    = review_codes_on_findings_by_user :expired

    assert_enqueued_emails 6 do
      Finding.remember_users_about_expiration
    end
  end

  test 'mark stale and confirmed findings as unanswered' do
    Organization.current_id = nil
    # Only if no weekend
    assert_not_includes [0, 6], Date.today.wday

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

    Organization.current_id = nil
    # Only if no weekend
    assert_not_includes [0, 6], Date.today.wday
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
    Organization.current_id = nil
    # Only if no weekend
    assert_not_includes [0, 6], Date.today.wday

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

  test 'work papers can be added to finding with current close date' do
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

  test 'unconfirmed for notification scope' do
    assert Finding.unconfirmed_for_notification.any?

    Finding.unconfirmed_for_notification.each do |finding|
      finding.update_column :first_notification_date,
        FINDING_DAYS_FOR_SECOND_NOTIFICATION.next.days.ago_in_business.to_date
    end

    refute Finding.unconfirmed_for_notification.any?
  end

  test 'next to expire scope' do
    before_expire = FINDING_WARNING_EXPIRE_DAYS.pred.days.from_now_in_business.to_date
    expire        = FINDING_WARNING_EXPIRE_DAYS.days.from_now_in_business.to_date

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
end
