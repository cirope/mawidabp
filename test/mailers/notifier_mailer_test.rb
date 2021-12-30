require 'test_helper'

class NotifierMailerTest < ActionMailer::TestCase
  fixtures :users, :findings, :organizations, :groups

  setup do
    ActionMailer::Base.deliveries.clear

    assert ActionMailer::Base.deliveries.empty?

    set_organization
  end

  teardown do
    Current.organization = nil
    Current.user         = nil
  end

  test 'pending poll email' do
    poll = Poll.find(polls(:poll_one).id)

    response = NotifierMailer.pending_poll_email(poll).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [poll.user.email], response.to
    assert response.subject.include?(
      poll.questionnaire.email_subject
    )
  end

  test 'group welcome email' do
    group = Group.find(groups(:main_group).id)
    response = NotifierMailer.group_welcome_email(group).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.group_welcome_email.title', :name => group.name)
    )
    assert_match %r{#{I18n.t('notifier.group_welcome_email.initial_user')}},
      response.body.decoded
    assert response.to.include?(group.admin_email)
  end

  test 'welcome email' do
    user = User.find(users(:first_time).id)
    organization = Organization.find(organizations(:cirope).id)
    response = NotifierMailer.welcome_email(user).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.welcome_email.title', :name => user.informal_name)
    )
    assert_match Regexp.new(I18n.t('notifier.welcome_email.initial_password')),
      response.body.decoded
    assert response.to.include?(user.email)
  end

  test 'notify new finding' do
    user = users :administrator
    response = NotifierMailer.notify_new_finding(user, user.findings.first).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.notify_new_finding.title', finding_id: user.findings.first.id)
    )
    assert_match Regexp.new(I18n.t('notifier.notify_new_finding.created_title')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'notify new finding to related users' do
    user = users :administrator
    related = users :bare

    user.related_user_relations.create! related_user_id: related.id, notify: true

    response = NotifierMailer.notify_new_finding(user, user.findings.first).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.notify_new_finding.title', finding_id: user.findings.first.id)
    )
    assert_match Regexp.new(I18n.t('notifier.notify_new_finding.created_title')),
      response.body.decoded
    assert_equal [user.email, related.email].sort, response.to.sort
  end

  test 'notify new oportunity' do
    user     = users :supervisor
    response = NotifierMailer.notify_new_oportunity([user], user.oportunities.first).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.notify_new_oportunity.title')
    )
    assert_match Regexp.new(I18n.t('notifier.notify_new_oportunity.title')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'findings brief' do
    user = users :administrator
    response = NotifierMailer.findings_brief(user, user.findings).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.findings_brief.title')
    )
    assert_match Regexp.new(I18n.t('notifier.findings_brief.title')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'notify new finding answer' do
    user           = users(:administrator)
    finding_answer = FindingAnswer.find(finding_answers(:auditor_answer).id)

    response = NotifierMailer.notify_new_finding_answer(user, finding_answer).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t(
        'notifier.notify_new_finding_answer.title',
        review: finding_answer.finding.review,
        finding_id: finding_answer.finding.id
      )
    )
    assert_match Regexp.new(I18n.t('notifier.notify_new_finding_answer.finding_link')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'notify action not found' do
    user    = users(:administrator)
    comment = 'comment'

    response = NotifierMailer.notify_action_not_found(user.email, comment).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert response.subject.include? I18n.t('notifier.notify_action_not_found.title')
    assert_match Regexp.new(comment), response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver stale notification' do
    user = User.find(users(:bare).id)
    response = NotifierMailer.stale_notification(user).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(I18n.t('notifier.notification.pending'))
    assert_match Regexp.new(I18n.t('notifier.notification.unconfirmed')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver unanswered finding notification' do
    finding = Finding.confirmed_and_stale.detect do |finding|
      !finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
    end

    user     = finding.users.first
    response = NotifierMailer.unanswered_finding_notification(user, finding).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t(
        'notifier.unanswered_finding.subject',
        finding_id: finding.id
      )
    )
    assert_match Regexp.new(I18n.t('notifier.unanswered_finding.title')),
                 response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver unanswered finding to manager notification' do
    finding  = Finding.find(findings(:unanswered_for_level_2_notification).id)
    users    = finding.users_for_scaffold_notification(1)
    response = NotifierMailer.unanswered_finding_to_manager_notification(finding, users, 1).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t(
        'notifier.unanswered_finding_to_manager.subject',
        finding_id: finding.id
      )
    )
    assert_match Regexp.new(
      I18n.t('notifier.unanswered_finding_to_manager.the_following_finding_is_stale_and_unanswered')
    ), response.body.decoded
    refute users.empty?
    assert users.map(&:email).all? { |email| response.to.include?(email) }
  end

  test 'deliver expired finding to manager notification' do
    finding  = findings(:being_implemented_weakness)
    users    = finding.users_for_scaffold_notification(1)
    response = NotifierMailer.expired_finding_to_manager_notification(finding, users, 1).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t(
        'notifier.expired_finding_to_manager.subject',
        finding_id: finding.id
      )
    )
    assert_match Regexp.new(
      I18n.t('notifier.expired_finding_to_manager.the_following_finding_is_expired')
    ), response.body.decoded
    refute users.empty?
    assert users.map(&:email).all? { |email| response.to.include?(email) }
  end

  test 'deliver reassigned findings notification' do
    user = User.find(users(:administrator).id)
    old = User.find(users(:administrator_second).id)
    response = NotifierMailer.reassigned_findings_notification(user, old, user.findings).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.reassigned_findings.title', :count => user.findings.size)
    )
    assert_match Regexp.new(I18n.t('notifier.reassigned_findings.title',
        :count => user.findings.size)),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'restore password notification' do
    user = User.find(users(:blank_password).id)
    organization = Organization.find(organizations(:cirope).id)
    response = NotifierMailer.restore_password(user, organization).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(I18n.t('notifier.restore_password.title'))
    assert response.body.decoded.include?(
      I18n.t(
        'notifier.restore_password.body_title',
        :user_name => user.informal_name, :user => user.user
      )
    )
    assert response.to.include?(user.email)
  end

  test 'changes notification' do
    user = User.find(users(:administrator).id)
    response = NotifierMailer.changes_notification(
      user,
      :title => 'test title',
      :content => 'test content',
      :notification => Notification.create(
        :user => user,
        :confirmation_hash => 'test_hash'
      )
    ).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.changes_notification.title')
    )
    assert_match /test title/, response.body.decoded
    assert_match /test content/, response.body.decoded
    assert_match /test_hash/, response.body.decoded
    assert_equal user.email, response.to.first

    assert_difference 'ActionMailer::Base.deliveries.size' do
      response = NotifierMailer.changes_notification(
        [user, User.find(users(:audited).id)], :title => 'test title',
        :content => ['test content 1', 'test content 2']).deliver_now
    end

    assert_match /test title/, response.body.decoded
    assert_match /test content 1/, response.body.decoded
    assert response.to.include?(user.email)
  end

  test 'conclusion review notification' do
    organization = Organization.find(organizations(:cirope).id)
    user = User.find(users(:administrator).id)
    conclusion_review = ConclusionFinalReview.find(conclusion_reviews(
        :conclusion_current_final_review).id)
    elements = [
      "#{Review.model_name.human} #{conclusion_review.review.identification}",
      I18n.t('conclusion_review.score_sheet'),
      I18n.t('conclusion_review.global_score_sheet')
    ]

    Current.organization = organization
    Current.user         = user

    conclusion_review.to_pdf organization
    conclusion_review.review.score_sheet organization, draft: false
    conclusion_review.review.global_score_sheet organization, draft: false

    response = NotifierMailer.conclusion_review_notification(user, conclusion_review,
      :include_score_sheet => true, :include_global_score_sheet => true,
      :note => 'note in **markdown**', :organization_id => Current.organization&.id,
      :user_id => PaperTrail.request.whodunnit).deliver_now
    title = I18n.t('notifier.conclusion_review_notification.title',
      :type => I18n.t('notifier.conclusion_review_notification.final'),
      :review => conclusion_review.review.long_identification)
    text_part = response.parts.detect {|p| p.content_type.match(/text/)}.body.decoded

    assert !ActionMailer::Base.deliveries.empty?

    if SHOW_ORGANIZATION_PREFIX_ON_REVIEW_NOTIFICATION.include?(organization.prefix)
      refute response.subject.include?(title)
    else
      assert response.subject.include?(title)
    end

    assert_equal 3, response.attachments.size
    assert_match /markdown/, text_part
    assert response.to.include?(user.email)

    elements.each do |element|
      assert text_part.include?(element)
    end

    response = NotifierMailer.conclusion_review_notification(user, conclusion_review,
      :include_score_sheet => true, :organization_id => Current.organization&.id,
      :user_id => PaperTrail.request.whodunnit).deliver_now
    title = I18n.t('notifier.conclusion_review_notification.title',
      :type => I18n.t('notifier.conclusion_review_notification.final'),
      :review => conclusion_review.review.long_identification)
    elements.delete(I18n.t('conclusion_review.global_score_sheet'))
    text_part = response.parts.detect {|p| p.content_type.match(/text/)}.body.decoded

    assert !ActionMailer::Base.deliveries.empty?

    if SHOW_ORGANIZATION_PREFIX_ON_REVIEW_NOTIFICATION.include?(organization.prefix)
      refute response.subject.include?(title)
    else
      assert response.subject.include?(title)
    end

    assert_equal 2, response.attachments.size
    assert response.to.include?(user.email)

    elements.each do |element|
      assert text_part.include?(element)
    end

    assert !text_part.include?(I18n.t('conclusion_review.global_score_sheet'))

    response = NotifierMailer.conclusion_review_notification(user,
      conclusion_review, :organization_id => Current.organization&.id,
      :user_id => PaperTrail.request.whodunnit).deliver_now
    title = I18n.t('notifier.conclusion_review_notification.title',
      :type => I18n.t('notifier.conclusion_review_notification.final'),
      :review => conclusion_review.review.long_identification)
    text_part = response.parts.detect {|p| p.content_type.match(/text/)}.body.decoded

    elements.delete(I18n.t('conclusion_review.score_sheet'))

    assert !ActionMailer::Base.deliveries.empty?

    if SHOW_ORGANIZATION_PREFIX_ON_REVIEW_NOTIFICATION.include?(organization.prefix)
      refute response.subject.include?(title)
    else
      assert response.subject.include?(title)
    end

    assert_equal 1, response.attachments.size
    assert response.to.include?(user.email)

    elements.each do |element|
      assert text_part.include?(element)
    end

    assert !text_part.include?(I18n.t('conclusion_review.score_sheet'))
    assert !text_part.include?(I18n.t('conclusion_review.global_score_sheet'))
  end

  test 'deliver findings expiration warning' do
    user = User.find(users(:administrator).id)
    response = NotifierMailer.findings_expiration_warning(user, user.findings).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.findings_expiration_warning.title')
    )
    assert_match Regexp.new(I18n.t('notifier.findings_expiration_warning.body_title',
        :count => user.findings.size)), response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver findings expired warning' do
    user = User.find(users(:administrator).id)
    response = NotifierMailer.findings_expired_warning(user, user.findings).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.findings_expired_warning.title')
    )
    assert_match Regexp.new(I18n.t('notifier.findings_expired_warning.body_title',
        :count => user.findings.size)), response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver tasks expiration warning' do
    user = User.find(users(:administrator).id)
    response = NotifierMailer.tasks_expiration_warning(user, user.tasks).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.tasks_expiration_warning.title')
    )
    assert_match Regexp.new(I18n.t('notifier.tasks_expiration_warning.body_title',
        :count => user.tasks.size)), response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver tasks expired warning' do
    user = User.find(users(:administrator).id)
    response = NotifierMailer.tasks_expired_warning(user, user.tasks).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.tasks_expired_warning.title')
    )
    assert_match Regexp.new(I18n.t('notifier.tasks_expired_warning.body_title',
        :count => user.tasks.size)), response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver findings unanswered warning' do
    user = User.find(users(:administrator).id)
    response = NotifierMailer.findings_unanswered_warning(user, user.findings).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.findings_unanswered_warning.title')
    )
    assert_match Regexp.new(
      I18n.t(
        'notifier.findings_unanswered_warning.body_title',
        :count => user.findings.size
      )
    ), response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver conclusion final review close date warning' do
    user = User.find(users(:supervisor).id)
    cfrs = user.conclusion_final_reviews
    response = NotifierMailer.conclusion_final_review_close_date_warning(user, cfrs).deliver_now

    assert !ActionMailer::Base.deliveries.empty?
    assert response.subject.include?(
      I18n.t('notifier.conclusion_final_review_close_date_warning.title')
    )
    assert_match Regexp.new(I18n.t('notifier.conclusion_final_review_close_date_warning.body_title')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'new admin user for first administrator' do
    user         = users :administrator
    organization = organizations :cirope

    organization.organization_roles.where(
      role_id: roles(:admin_role).id
    ).where.not(user_id: user.id).delete_all

    response = NotifierMailer.new_admin_user(organization.id, user.email).deliver_now

    assert_nil response
    assert ActionMailer::Base.deliveries.empty?
  end

  test 'new admin user' do
    user         = users :audited
    organization = organizations :cirope

    user.organization_roles.where(
      organization_id: organization.id
    ).update_all role_id: roles(:admin_role).id

    response = NotifierMailer.new_admin_user(organization.id, user.email).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert_not_includes response.to, user.email
  end

  test 'new endorsement' do
    endorsement  = endorsements :reschedule
    organization = endorsement.organization
    user         = endorsement.user

    response = NotifierMailer.new_endorsement(organization.id, endorsement.id).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert_includes response.to, user.email
  end

  test 'endorsement update' do
    endorsement  = endorsements :reschedule
    organization = endorsement.organization
    user         = endorsement.user
    users        = endorsement.finding.users - [user]

    response = NotifierMailer.endorsement_update(organization.id, endorsement.id).deliver_now

    refute ActionMailer::Base.deliveries.empty?
    assert_equal response.to.sort, users.map(&:email).sort
  end

  test 'notify implemented finding with follow up date last changed greater than 90 days' do
    finding                = findings :being_implemented_weakness
    finding.follow_up_date = Time.zone.today - 91.days

    finding.save!

    response = NotifierMailer.notify_implemented_finding_with_follow_up_date_last_changed_greater_than_90_days(finding)
                             .deliver_now

    refute ActionMailer::Base.deliveries.empty?

    expected_emails_to_send = finding.finding_user_assignments
                                     .joins(user: { organization_roles: :role })
                                     .where('roles.role_type = ?', ::Role::TYPES[:supervisor])
                                     .map { |f_u_a| f_u_a.user }
                                     .map(&:email)

    assert_equal response.to.sort, expected_emails_to_send.sort
  end
end
