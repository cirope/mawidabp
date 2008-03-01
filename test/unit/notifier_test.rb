require 'test_helper'

class NotifierTest < ActionMailer::TestCase
  fixtures :users, :findings, :organizations

  test 'welcome email' do
    user = User.find(users(:first_time_user).id)
    organization = Organization.find(organizations(:default_organization).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_welcome_email(user)

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.welcome_email.title',
      :name => user.informal_name), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.welcome_email.initial_password')),
      response.body
    assert response.to.include?(user.email)
  end

  test 'notify new findings' do
    user = User.find(users(:administrator_user).id)
    finding = user.findings.for_notification

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_notify_new_findings(user)

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.notify_new_findings.title'), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.notify_new_findings.created_title',
        :count => finding.size)), response.body
    assert_equal user.email, response.to.first
  end

  test 'notify new finding' do
    user = User.find(users(:administrator_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_notify_new_finding(user, user.findings.first)

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.notify_new_finding.title'), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.notify_new_finding.title')),
      response.body
    assert_equal user.email, response.to.first
  end

  test 'notify new finding answer' do
    user = User.find(users(:administrator_user).id)
    finding_answer = FindingAnswer.find(finding_answers(
        :bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity_auditor_answer).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_notify_new_finding_answer(user, finding_answer)

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.notify_new_finding_answer.title'),
      response.subject
    assert_match Regexp.new(I18n.t(:'notifier.notify_new_finding_answer.finding_link')),
      response.body
    assert_equal user.email, response.to.first
  end

  test 'deliver stale notification' do
    user = User.find(users(:bare_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_stale_notification(user)

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.notification.pending'), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.notification.unconfirmed')),
      response.body
    assert_equal user.email, response.to.first
  end

  test 'deliver unanswered findings notification' do
    finding = Finding.confirmed_and_stale.select do |finding|
      !finding.finding_answers.detect { |fa| fa.user.audited? }
    end
    user = finding.first.users.first

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_unanswered_findings_notification(user, finding)

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.unanswered_findings.title'), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.unanswered_findings.title')),
      response.body
    assert_equal user.email, response.to.first
  end

  test 'deliver reassigned findings notification' do
    user = User.find(users(:administrator_user).id)
    old_user = User.find(users(:administrator_second_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_reassigned_findings_notification(user, old_user,
      user.findings)

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.reassigned_findings.title',
      :count => user.findings.size),
      response.subject
    assert_match Regexp.new(I18n.t(:'notifier.reassigned_findings.title',
        :count => user.findings.size)),
      response.body
    assert_equal user.email, response.to.first
  end

  test 'blank password notification' do
    user = User.find(users(:blank_password_user).id)
    organization = Organization.find(organizations(:default_organization).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_blank_password_notification(user, organization)

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.blank_password.title'), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.blank_password.body_title')),
      response.body
    assert response.to.include?(user.email)
  end

  test 'changes notification' do
    user = User.find(users(:administrator_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_changes_notification(
      user,
      :title => 'test title',
      :content => 'test content',
      :notification => Notification.create(
        :user => user,
        :confirmation_hash => 'test_hash'
      )
    )

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.changes_notification.title'),
      response.subject
    assert_match /test title/, response.body
    assert_match /test content/, response.body
    assert_match /test_hash/, response.body
    assert_equal user.email, response.to.first

    assert_difference 'ActionMailer::Base.deliveries.size' do
      response = Notifier.deliver_changes_notification(
        [user, User.find(users(:audited_user).id)], :title => 'test title',
        :content => ['test content 1', 'test content 2'])
    end

    assert_match /test title/, response.body
    assert_match /test content 1/, response.body
    assert response.to.include?(user.email)
  end

  test 'conclusion review notification' do
    organization = Organization.find(organizations(
          :default_organization).id)
    user = User.find(users(:administrator_user).id)
    conclusion_review = ConclusionFinalReview.find(conclusion_reviews(
        :conclusion_current_final_review).id)
    elements = [
      "#{Review.human_name} #{conclusion_review.review.identification}",
      I18n.t(:'conclusion_review.score_sheet'),
      I18n.t(:'conclusion_review.global_score_sheet')
    ]

    GlobalModelConfig.current_organization_id = organization.id

    conclusion_review.to_pdf organization
    conclusion_review.review.score_sheet organization, false
    conclusion_review.review.global_score_sheet organization, false

    assert ActionMailer::Base.deliveries.empty?

    assert_difference 'Notification.count' do
      response = Notifier.deliver_conclusion_review_notification(user,
        conclusion_review, :notify => true, :include_score_sheet => true,
        :include_global_score_sheet => true, :note => 'note in *textile*')
      title = I18n.t(:'notifier.conclusion_review_notification.title',
        :review => conclusion_review.review.identification)

      assert !ActionMailer::Base.deliveries.empty?
      assert_equal title, response.subject
      assert_equal 3, response.attachments.size
      assert_match /textile/, response.body
      assert response.to.include?(user.email)

      elements.each do |element|
        assert response.body.include?(element)
      end
    end

    assert_no_difference 'Notification.count' do
      response = Notifier.deliver_conclusion_review_notification(user,
        conclusion_review, :notify => false, :include_score_sheet => true)
      title = I18n.t(:'notifier.conclusion_review_notification.title',
        :review => conclusion_review.review.identification)
      elements.delete(I18n.t(:'conclusion_review.global_score_sheet'))

      assert !ActionMailer::Base.deliveries.empty?
      assert_equal title, response.subject
      assert_equal 2, response.attachments.size
      assert response.to.include?(user.email)

      elements.each do |element|
        assert response.body.include?(element)
      end

      assert !response.body.include?(
        I18n.t(:'conclusion_review.global_score_sheet'))
    end

    assert_no_difference 'Notification.count' do
      response = Notifier.deliver_conclusion_review_notification(user,
        conclusion_review, :notify => false)
      title = I18n.t(:'notifier.conclusion_review_notification.title',
        :review => conclusion_review.review.identification)

      elements.delete(I18n.t(:'conclusion_review.score_sheet'))

      assert !ActionMailer::Base.deliveries.empty?
      assert_equal title, response.subject
      assert_equal 1, response.attachments.size
      assert response.to.include?(user.email)

      elements.each do |element|
        assert response.body.include?(element)
      end

      assert !response.body.include?(
        I18n.t(:'conclusion_review.score_sheet'))
      assert !response.body.include?(
        I18n.t(:'conclusion_review.global_score_sheet'))
    end
  end

  test 'deliver findings expiration warning' do
    user = User.find(users(:administrator_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.deliver_findings_expiration_warning(user, user.findings)

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.findings_expiration_warning.title'),
      response.subject
    assert_match Regexp.new(I18n.t(:'notifier.findings_expiration_warning.body_title',
        :count => user.findings.size)), response.body
    assert_equal user.email, response.to.first
  end
end