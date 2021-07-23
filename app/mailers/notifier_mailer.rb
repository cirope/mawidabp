class NotifierMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper

  helper :application, :markdown, :notifier

  default from: "#{ENV['EMAIL_NAME'] || I18n.t('app_name')} <#{ENV['EMAIL_ADDRESS']}>"

  def pending_poll_email(poll)
    @poll = poll
    @organization = poll.organization
    @token = poll.access_token
    @user = poll.user.informal_name
    email = poll.user.email
    subject = "[#{@organization.prefix.upcase}] #{poll.questionnaire.email_subject}"

    subject << " - #{poll.about.display_name}" if poll.about

    mail to: email, subject: subject
  end

  def group_welcome_email(group)
    @group, @hash = group, group.admin_hash
    prefixes = group.organizations.to_a.uniq.map { |o| "[#{o.prefix}]" }.join(' ')

    prefixes << ' ' unless prefixes.blank?

    mail to: [group.admin_email],
         subject: prefixes.upcase + t(
           'notifier.group_welcome_email.title', name: group.name
         )
  end

  def welcome_email(user)
    @user, @hash = user, user.change_password_hash
    prefixes = user.organizations.to_a.uniq.map { |o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail to: [user.email],
         subject: prefixes.upcase + t(
           'notifier.welcome_email.title', name: user.informal_name
         )
  end

  def notify_new_finding(user, finding)
    @user, @finding = user, finding
    prefix = "[#{finding.organization.prefix}] "

    if @finding.notify? || @finding.unconfirmed?
      @notification = Notification.create(user: user, findings: [finding])
    end

    mail to: users_to_notify_for(user).map(&:email),
         subject: prefix.upcase + t(
           'notifier.notify_new_finding.title',
           finding_id: finding.id
        )
  end

  def findings_brief(user, findings)
    @user, @findings = user, findings
    prefix = "[#{findings.first.organization.prefix}] "

    mail to: users_to_notify_for(user).map(&:email),
         subject: prefix.upcase + t('notifier.findings_brief.title')
  end

  def notify_new_finding_answer(users, finding_answer)
    @finding_answer = finding_answer
    prefix = "[#{finding_answer.finding.organization.prefix}] "

    mail to: users_to_notify_for(users).map(&:email),
         subject: prefix.upcase + t(
           'notifier.notify_new_finding_answer.title',
           review:     finding_answer.finding.review,
           finding_id: finding_answer.finding.id
         )
  end

  def notify_action_not_found(email, answer)
    @answer = answer

    mail to: email,
         subject: t('notifier.notify_action_not_found.title')
  end

  def stale_notification(user)
    @notifications = user.notifications.not_confirmed
    organizations = @notifications.map do |n|
      n.findings.map(&:organization)
    end.flatten.uniq
    prefixes = organizations.map {|o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail to: users_to_notify_for(user).map(&:email),
         subject: prefixes.upcase + t('notifier.notification.pending')
  end

  def unanswered_findings_notification(user, findings)
    filtered_findings = findings.select {|f| f.users.any? {|u| u.id == user.id}}

    unless filtered_findings.empty?
      @grouped_findings = filtered_findings.group_by(&:organization)
      prefixes = @grouped_findings.keys.map {|o| "[#{o.prefix}]" }.join(' ')
      prefixes << ' ' unless prefixes.blank?

      mail to: users_to_notify_for(user).map(&:email),
           subject: prefixes.upcase + t('notifier.unanswered_findings.title')
    else
      raise 'Findings and user mismatch'
    end
  end

  def unanswered_finding_to_manager_notification(finding, users, level)
    @finding, @level = finding, level
    prefix = "[#{finding.organization.prefix}] ".upcase

    mail to: users_to_notify_for(users).map(&:email),
         subject: prefix + t('notifier.unanswered_finding_to_manager.title')
  end

  def expired_finding_to_manager_notification(finding, users, level)
    @finding, @level = finding, level
    prefix = "[#{finding.organization.prefix}] ".upcase

    mail to: users_to_notify_for(users).map(&:email),
         subject: prefix + t('notifier.expired_finding_to_manager.title')
  end

  def reassigned_findings_notification(new_users, old_users, findings, notify = true)
    findings_array = findings.respond_to?(:each) ? findings.to_a : [findings]

    @new_users, @old_users = Array(new_users), Array(old_users)
    @grouped_findings = findings_array.group_by(&:organization)
    @notification = notify ?
      Notification.create(findings: findings_array, user: new_users) : nil
    prefixes = @grouped_findings.keys.map {|o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail to: users_to_notify_for([new_users, old_users].flatten.compact).map(&:email),
         subject: prefixes.upcase + t(
           'notifier.reassigned_findings.title',
           count: findings_array.size
         )
  end

  def restore_password(user, organization)
    @user, @hash = user, user.change_password_hash
    @organization = organization
    prefix = organization ? "[#{organization.prefix}] " : ''

    mail to: [user.email],
         subject: prefix.upcase + t('notifier.restore_password.title')
  end

  def changes_notification(users, options)
    @title = options[:title]
    @content = options[:content]
    @body = options[:body]
    @notification = options[:notification]
    option_organizations = options[:organizations] ?
      options[:organizations].uniq : []
    organizations = @notification ?
      @notification.findings.map(&:organization).uniq : []
    organizations += option_organizations

    prefixes = organizations.uniq.map { |o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail to: users_to_notify_for(users).map(&:email),
         subject: prefixes.upcase + t('notifier.changes_notification.title')
  end

  def conclusion_review_notification(user, conclusion_review, options = {})
    Current.organization = Organization.find(options.delete :organization_id)
    PaperTrail.request.whodunnit = options.delete :user_id

    org_prefix = conclusion_review.review.organization.prefix
    prefix = "[#{org_prefix}] "
    type = conclusion_review.kind_of?(ConclusionDraftReview) ? 'draft' : 'final'
    type_text = I18n.t "notifier.conclusion_review_notification.#{type}"

    if SHOW_ORGANIZATION_PREFIX_ON_REVIEW_NOTIFICATION.include?(org_prefix)
      type_text = "#{org_prefix} #{type_text}"
    end

    title = I18n.t(
      'notifier.conclusion_review_notification.title',
      type: type_text,
      review: conclusion_review.review.long_identification
    )
    elements = [
      "**#{Review.model_name.human} #{conclusion_review.review.identification}**"
    ]

    if options[:include_score_sheet]
      elements << "**#{I18n.t('conclusion_review.score_sheet')}**"
    end

    if options[:include_global_score_sheet]
      elements << "**#{I18n.t('conclusion_review.global_score_sheet')}**"
    end

    body_title = I18n.t('notifier.conclusion_review_notification.body_title',
      elements: elements.to_sentence)

    @conclusion_review = conclusion_review
    @organization = conclusion_review.review.organization
    @body_title = body_title
    @note = options[:note]

    if conclusion_review.review.show_counts?(org_prefix)
      @show_alt_footer = true
    end

    if File.exist?(conclusion_review.absolute_pdf_path)
      attachments[conclusion_review.pdf_name] =
        File.read(conclusion_review.absolute_pdf_path)
    end

    if options[:include_score_sheet] &&
        File.exist?(conclusion_review.review.absolute_score_sheet_path)
      attachments[conclusion_review.review.score_sheet_name] =
        File.read(conclusion_review.review.absolute_score_sheet_path)
    end

    if options[:include_global_score_sheet] &&
        File.exist?(conclusion_review.review.absolute_global_score_sheet_path)
      attachments[conclusion_review.review.global_score_sheet_name] =
        File.read(conclusion_review.review.absolute_global_score_sheet_path)
    end

    mail to: users_to_notify_for(user).map(&:email),
         subject: truncate(prefix.upcase + title, length: 990)
  end

  def findings_expiration_warning(user, findings)
    @grouped_findings = findings.group_by(&:organization)
    prefixes = @grouped_findings.keys.map {|o| "[#{o.prefix}]" }.join(' ')

    prefixes << ' ' unless prefixes.blank?

    mail to: users_to_notify_for(user).map(&:email),
         subject: prefixes.upcase + t('notifier.findings_expiration_warning.title')
  end

  def findings_expired_warning(user, findings)
    @grouped_findings = findings.group_by(&:organization)
    prefixes = @grouped_findings.keys.map {|o| "[#{o.prefix}]" }.join(' ')

    prefixes << ' ' unless prefixes.blank?

    mail to: users_to_notify_for(user).map(&:email),
         subject: prefixes.upcase + t('notifier.findings_expired_warning.title')
  end

  def findings_unanswered_warning(user, findings)
    @grouped_findings = findings.group_by(&:organization)
    prefixes = @grouped_findings.keys.map {|o| "[#{o.prefix}]" }.join(' ')

    prefixes << ' ' unless prefixes.blank?

    mail to: users_to_notify_for(user).map(&:email),
         subject: prefixes.upcase + t('notifier.findings_unanswered_warning.title')
  end

  def tasks_expiration_warning(user, tasks)
    @grouped_tasks = tasks.group_by(&:organization)
    prefixes = @grouped_tasks.keys.map {|o| "[#{o.prefix}]" }.join(' ')

    prefixes << ' ' unless prefixes.blank?

    mail to: users_to_notify_for(user).map(&:email),
         subject: prefixes.upcase + t('notifier.tasks_expiration_warning.title')
  end

  def tasks_expired_warning(user, tasks)
    @grouped_tasks = tasks.group_by(&:organization)
    prefixes = @grouped_tasks.keys.map {|o| "[#{o.prefix}]" }.join(' ')

    prefixes << ' ' unless prefixes.blank?

    mail to: users_to_notify_for(user).map(&:email),
         subject: prefixes.upcase + t('notifier.tasks_expired_warning.title')
  end

  def conclusion_final_review_close_date_warning(user, conclusion_final_reviews)
    @grouped_conclusion_reviews = conclusion_final_reviews.group_by(&:organization)
    prefixes = @grouped_conclusion_reviews.keys.map {|o| "[#{o.prefix}]" }.join(' ')

    prefixes << ' ' unless prefixes.blank?

    mail to: users_to_notify_for(user).map(&:email),
         subject: "#{prefixes.upcase} #{t 'notifier.conclusion_final_review_close_date_warning.title'}"
  end

  def new_admin_user organization_id, email
    @organization        = Organization.find organization_id
    Current.organization = @organization

    @user   = @organization.users.find_by email: email
    prefix  = @organization.prefix.upcase
    emails  = @organization.users.not_hidden.enabled.with_role(:admin).distinct.pluck :email
    emails -= [@user.email]

    return if emails.empty? # only one administrator

    mail to: emails,
         subject: "[#{prefix}] #{t 'notifier.new_admin_user.title'}"
  end

  def new_endorsement organization_id, endorsement_id
    @organization        = Organization.find organization_id
    @endorsement         = Endorsement.find endorsement_id
    Current.organization = @organization

    @user           = @endorsement.user
    @finding        = @endorsement.finding
    @finding_answer = @endorsement.finding_answer
    prefix          = @organization.prefix.upcase

    mail to: users_to_notify_for(@user).map(&:email),
         subject: "[#{prefix}] #{t 'notifier.new_endorsement.title'}"
  end

  def endorsement_update organization_id, endorsement_id
    @organization        = Organization.find organization_id
    @endorsement         = Endorsement.find endorsement_id
    Current.organization = @organization

    @user           = @endorsement.user
    @finding        = @endorsement.finding
    @finding_answer = @endorsement.finding_answer
    prefix          = @organization.prefix.upcase
    users           = @finding.users - [@user]

    mail to: users_to_notify_for(users).map(&:email),
         subject: "[#{prefix}] #{t 'notifier.endorsement_update.title'}"
  end

  def notify_new_oportunity(users, oportunity)
    @oportunity = oportunity
    prefix      = "[#{@oportunity.organization.prefix}]"

    mail to: users_to_notify_for(users).map(&:email),
         subject: prefix.upcase + t('notifier.notify_new_oportunity.title')
  end

  private

    def users_to_notify_for(users)
      extra_users = []

      Array(users).each do |user|
        user.related_user_relations.includes(:related_user).where(notify: true).each do |rur|
          extra_users << rur.related_user
        end
      end

      Array(users).concat(extra_users)
    end
end
