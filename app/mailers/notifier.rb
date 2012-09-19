class Notifier < ActionMailer::Base
  helper :application
  default :from => "\"#{I18n.t('app_name')}\" <#{NOTIFICATIONS_EMAIL}>",
    :charset => 'UTF-8', :content_type => 'text/html',
    :date => proc { Time.now }

  def pending_poll_email(poll)
    @poll = poll
    @user = poll.user
    @hash = @user.change_password_hash
    @organization = poll.organization
    @token = poll.access_token

    mail(
      :to => @user.email,
      :subject => "[#{@organization.prefix.upcase}] " + t(
        'notifier.pending_poll_email.title', :name => @user.informal_name
      )
    )
  end

  def group_welcome_email(group)
    @group, @hash = group, group.admin_hash
    prefixes = group.organizations.map { |o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail(
      :to => [group.admin_email],
      :subject => prefixes.upcase + t(
        'notifier.group_welcome_email.title', :name => group.name
      )
    )
  end

  def welcome_email(user)
    @user, @hash = user, user.change_password_hash
    prefixes = user.organizations.map {|o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail(
      :to => [user.email],
      :subject => prefixes.upcase + t(
        'notifier.welcome_email.title', :name => user.informal_name
      )
    )
  end

  def notify_new_findings(user)
    findings = user.findings.for_notification

    @user = user
    @grouped_findings = findings.group_by(&:organization)
    @notification = Notification.create(:user => user, :findings => findings)
    prefixes = @grouped_findings.keys.map { |o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail(
      :to => [user.email],
      :subject => prefixes.upcase + t('notifier.notify_new_findings.title')
    )
  end

  def notify_new_finding(user, finding)
    @user, @finding = user, finding
    @notification = Notification.create(:user => user, :findings => [finding])
    prefix = "[#{finding.organization.prefix}] "

    mail(
      :to => [user.email],
      :subject => prefix.upcase + t('notifier.notify_new_finding.title')
    )
  end

  def notify_new_finding_answer(users, finding_answer)
    @finding_answer = finding_answer
    prefix = "[#{finding_answer.finding.organization.prefix}] "

    mail(
      :to => users.kind_of?(Array) ? users.map(&:email) : [users.email],
      :subject => prefix.upcase + t(
        'notifier.notify_new_finding_answer.title',
        :review => finding_answer.finding.review.to_s
      )
    )
  end

  def stale_notification(user)
    @notifications = user.notifications.not_confirmed
    organizations = @notifications.map do |n|
      n.findings.map(&:organization)
    end.flatten.uniq
    prefixes = organizations.map {|o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail(
      :to => [user.email],
      :subject => prefixes.upcase + t('notifier.notification.pending')
    )
  end

  def unanswered_findings_notification(user, findings)
    filtered_findings = findings.select {|f| f.users.any? {|u| u.id == user.id}}

    unless filtered_findings.empty?
      @grouped_findings = filtered_findings.group_by(&:organization)
      prefixes = @grouped_findings.keys.map {|o| "[#{o.prefix}]" }.join(' ')
      prefixes << ' ' unless prefixes.blank?

      mail(
        :to => [user.email],
        :subject => prefixes.upcase + t('notifier.unanswered_findings.title')
      )
    else
      raise 'Findings and user mismatch'
    end
  end

  def unanswered_finding_to_manager_notification(finding, users, level)
    @finding, @level = finding, level
    prefix = "[#{finding.organization.prefix}] ".upcase

    mail(
      :to => users.map(&:email),
      :subject => prefix + t('notifier.unanswered_finding_to_manager.title')
    )
  end

  def reassigned_findings_notification(new_users, old_users, findings,
      notify = true)
    findings_array = findings.kind_of?(Array) ? findings : [findings]

    @new_users, @old_users = [new_users].flatten, [old_users].flatten
    @grouped_findings = findings_array.group_by(&:organization)
    @notification = notify ?
      Notification.create(:findings => findings_array, :user => new_users) : nil
    prefixes = @grouped_findings.keys.map {|o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail(
      :to => [new_users, old_users].flatten.compact.map(&:email),
      :subject => prefixes.upcase + t(
        'notifier.reassigned_findings.title',
        :count => findings_array.size
      )
    )
  end

  def restore_password(user, organization)
    @user, @hash = user, user.change_password_hash
    @organization = organization
    prefix = "[#{organization.prefix}] "

    mail(
      :to => [user.email],
      :subject => prefix.upcase + t('notifier.restore_password.title')
    )
  end

  def changes_notification(users, options)
    @title = options[:title]
    @content = options[:content]
    @body = options[:body]
    @notification = options[:notification]
    organizations = @notification ?
      @notification.findings.map(&:organization).uniq : []
    prefixes = organizations.map {|o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail(
      :to => users.kind_of?(Array) ? users.map(&:email) : [users.email],
      :subject => prefixes.upcase + t('notifier.changes_notification.title')
    )
  end

  def conclusion_review_notification(user, conclusion_review, options = {})
    raise 'lala' if options.has_key?(:notify)
    prefix = "[#{conclusion_review.review.organization.prefix}] "
    title = I18n.t(
      'notifier.conclusion_review_notification.title',
      :review => conclusion_review.review.identification
    )
    elements = [
      "*#{Review.model_name.human} #{conclusion_review.review.identification}*"
    ]

    if options[:include_score_sheet]
      elements << "*#{I18n.t('conclusion_review.score_sheet')}*"
    end

    if options[:include_global_score_sheet]
      elements << "*#{I18n.t('conclusion_review.global_score_sheet')}*"
    end

    body_title = I18n.t('notifier.conclusion_review_notification.body_title',
      :elements => elements.to_sentence)

    @conclusion_review = conclusion_review
    @body_title = body_title
    @note = options[:note]

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

    mail(:to => [user.email], :subject => prefix.upcase + title)
  end

  def findings_expiration_warning(user, findings)
    @grouped_findings = findings.group_by(&:organization)
    prefixes = @grouped_findings.keys.map {|o| "[#{o.prefix}]" }.join(' ')
    prefixes << ' ' unless prefixes.blank?

    mail(
      :to => [user.email],
      :subject => prefixes.upcase + t(
        'notifier.findings_expiration_warning.title'
      )
    )
  end
end
