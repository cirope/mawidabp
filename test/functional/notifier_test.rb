require 'test_helper'

class NotifierTest < ActionMailer::TestCase
  fixtures :users, :findings, :organizations, :groups

  test 'group welcome email' do
    group = Group.find(groups(:main_group).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.group_welcome_email(group).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.group_welcome_email.title',
      :name => group.name), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.group_welcome_email.initial_user')),
      response.body.decoded
    assert response.to.include?(group.admin_email)
  end

  test 'welcome email' do
    user = User.find(users(:first_time_user).id)
    organization = Organization.find(organizations(:default_organization).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.welcome_email(user).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.welcome_email.title',
      :name => user.informal_name), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.welcome_email.initial_password')),
      response.body.decoded
    assert response.to.include?(user.email)
  end

  test 'notify new findings' do
    user = User.find(users(:administrator_user).id)
    finding = user.findings.for_notification

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.notify_new_findings(user).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.notify_new_findings.title'), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.notify_new_findings.created_title',
        :count => finding.size)), response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'notify new finding' do
    user = User.find(users(:administrator_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.notify_new_finding(user, user.findings.first).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.notify_new_finding.title'), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.notify_new_finding.title')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'notify new finding answer' do
    user = User.find(users(:administrator_user).id)
    finding_answer = FindingAnswer.find(finding_answers(
        :bcra_A4609_data_proccessing_impact_analisys_confirmed_oportunity_auditor_answer).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.notify_new_finding_answer(user, finding_answer).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.notify_new_finding_answer.title'),
      response.subject
    assert_match Regexp.new(I18n.t(:'notifier.notify_new_finding_answer.finding_link')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver stale notification' do
    user = User.find(users(:bare_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.stale_notification(user).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.notification.pending'), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.notification.unconfirmed')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver unanswered findings notification' do
    finding = Finding.confirmed_and_stale.select do |finding|
      !finding.finding_answers.detect { |fa| fa.user.can_act_as_audited? }
    end
    user = finding.first.users.first

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.unanswered_findings_notification(user, finding).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.unanswered_findings.title'), response.subject
    assert_match Regexp.new(I18n.t(:'notifier.unanswered_findings.title')),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'deliver unanswered finding to manager notification' do
    finding = Finding.find(findings(
        :iso_27000_security_organization_4_2_item_editable_weakness_unanswered_for_level_2_notification).id)
    users = finding.users_for_scaffold_notification(1)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.unanswered_finding_to_manager_notification(finding, users,
      1).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.unanswered_finding_to_manager.title'),
      response.subject
    assert_match Regexp.new(I18n.t(
        :'notifier.unanswered_finding_to_manager.the_following_finding_is_stale_and_unanswered')),
      response.body.decoded
    assert !users.empty?
    assert users.map(&:email).all? { |email| response.to.include?(email) }
  end

  test 'deliver reassigned findings notification' do
    user = User.find(users(:administrator_user).id)
    old_user = User.find(users(:administrator_second_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.reassigned_findings_notification(user, old_user,
      user.findings).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.reassigned_findings.title',
      :count => user.findings.size),
      response.subject
    assert_match Regexp.new(I18n.t(:'notifier.reassigned_findings.title',
        :count => user.findings.size)),
      response.body.decoded
    assert_equal user.email, response.to.first
  end

  test 'blank password notification' do
    user = User.find(users(:blank_password_user).id)
    organization = Organization.find(organizations(:default_organization).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.blank_password_notification(user, organization).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.blank_password.title'), response.subject
    assert response.body.decoded.include?(I18n.t(
        :'notifier.blank_password.body_title', :user_name => user.informal_name,
        :user => user.user))
    assert response.to.include?(user.email)
  end

  test 'changes notification' do
    user = User.find(users(:administrator_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.changes_notification(
      user,
      :title => 'test title',
      :content => 'test content',
      :notification => Notification.create(
        :user => user,
        :confirmation_hash => 'test_hash'
      )
    ).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.changes_notification.title'),
      response.subject
    assert_match /test title/, response.body.decoded
    assert_match /test content/, response.body.decoded
    assert_match /test_hash/, response.body.decoded
    assert_equal user.email, response.to.first

    assert_difference 'ActionMailer::Base.deliveries.size' do
      response = Notifier.changes_notification(
        [user, User.find(users(:audited_user).id)], :title => 'test title',
        :content => ['test content 1', 'test content 2']).deliver
    end

    assert_match /test title/, response.body.decoded
    assert_match /test content 1/, response.body.decoded
    assert response.to.include?(user.email)
  end

  test 'conclusion review notification' do
    organization = Organization.find(organizations(
          :default_organization).id)
    user = User.find(users(:administrator_user).id)
    conclusion_review = ConclusionFinalReview.find(conclusion_reviews(
        :conclusion_current_final_review).id)
    elements = [
      "#{Review.model_name.human} #{conclusion_review.review.identification}",
      I18n.t(:'conclusion_review.score_sheet'),
      I18n.t(:'conclusion_review.global_score_sheet')
    ]

    GlobalModelConfig.current_organization_id = organization.id

    conclusion_review.to_pdf organization
    conclusion_review.review.score_sheet organization, false
    conclusion_review.review.global_score_sheet organization, false

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.conclusion_review_notification(user, conclusion_review,
      :include_score_sheet => true, :include_global_score_sheet => true,
      :note => 'note in *textile*').deliver
    title = I18n.t(:'notifier.conclusion_review_notification.title',
      :review => conclusion_review.review.identification)
    text_part = response.parts.detect {|p| p.content_type.match(/text/)}.body.decoded

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal title, response.subject
    assert_equal 3, response.attachments.size
    assert_match /textile/, text_part
    assert response.to.include?(user.email)

    elements.each do |element|
      assert text_part.include?(element)
    end

    response = Notifier.conclusion_review_notification(user, conclusion_review,
      :include_score_sheet => true).deliver
    title = I18n.t(:'notifier.conclusion_review_notification.title',
      :review => conclusion_review.review.identification)
    elements.delete(I18n.t(:'conclusion_review.global_score_sheet'))
    text_part = response.parts.detect {|p| p.content_type.match(/text/)}.body.decoded

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal title, response.subject
    assert_equal 2, response.attachments.size
    assert response.to.include?(user.email)

    elements.each do |element|
      assert text_part.include?(element)
    end

    assert !text_part.include?(I18n.t(:'conclusion_review.global_score_sheet'))

    response = Notifier.conclusion_review_notification(user,
      conclusion_review).deliver
    title = I18n.t(:'notifier.conclusion_review_notification.title',
      :review => conclusion_review.review.identification)
    text_part = response.parts.detect {|p| p.content_type.match(/text/)}.body.decoded

    elements.delete(I18n.t(:'conclusion_review.score_sheet'))

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal title, response.subject
    assert_equal 1, response.attachments.size
    assert response.to.include?(user.email)

    elements.each do |element|
      assert text_part.include?(element)
    end

    assert !text_part.include?(I18n.t(:'conclusion_review.score_sheet'))
    assert !text_part.include?(I18n.t(:'conclusion_review.global_score_sheet'))
  end

  test 'deliver findings expiration warning' do
    user = User.find(users(:administrator_user).id)

    assert ActionMailer::Base.deliveries.empty?

    response = Notifier.findings_expiration_warning(user, user.findings).deliver

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal I18n.t(:'notifier.findings_expiration_warning.title'),
      response.subject
    assert_match Regexp.new(I18n.t(:'notifier.findings_expiration_warning.body_title',
        :count => user.findings.size)), response.body.decoded
    assert_equal user.email, response.to.first
  end
end