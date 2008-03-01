class Notifier < ActionMailer::Base

  def welcome_email(user)
    subject I18n.t(:'notifier.welcome_email.title', :name => user.informal_name)
    recipients [user.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body :user => user, :hash => user.change_password_hash
  end

  def notify_new_findings(user)
    findings = user.findings.for_notification

    subject I18n.t(:'notifier.notify_new_findings.title')
    recipients [user.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body(
      :user => user,
      :grouped_findings => findings.group_by(&:organization),
      :notification => Notification.create(
        :user_id => user.id,
        :findings => findings
      )
    )
  end

  def notify_new_finding(user, finding)
    subject I18n.t(:'notifier.notify_new_finding.title')
    recipients [user.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body(
      :user => user,
      :finding => finding,
      :notification => Notification.create(
        :user_id => user.id,
        :findings => [finding]
      )
    )
  end

  def notify_new_finding_answer(users, finding_answer)
    subject I18n.t(:'notifier.notify_new_finding_answer.title')
    recipients users.kind_of?(Array) ? users.map(&:email) : [users.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body :finding_answer => finding_answer
  end

  def stale_notification(user)
    subject I18n.t(:'notifier.notification.pending')
    recipients [user.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body :notifications => user.notifications.not_confirmed
  end

  def unanswered_findings_notification(user, findings)
    filtered_findings = findings.select {|f| f.users.any? {|u| u.id == user.id}}

    subject I18n.t(:'notifier.unanswered_findings.title')
    recipients [user.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body :grouped_findings => filtered_findings.group_by(&:organization)
  end

  def reassigned_findings_notification(new_users, old_users, findings,
      notify = true)
    findings_array = findings.kind_of?(Array) ? findings : [findings]
    
    subject I18n.t(:'notifier.reassigned_findings.title',
      :count => findings_array.size)
    recipients [new_users, old_users].flatten.compact.map(&:email)
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body(
      :new_users => [new_users].flatten,
      :old_users => [old_users].flatten,
      :grouped_findings => findings_array.group_by(&:organization),
      :notification => notify ? Notification.create(:findings => findings_array,
        :user => new_users) : nil
    )
  end

  def blank_password_notification(user, organization)
    subject I18n.t(:'notifier.blank_password.title')
    recipients [user.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body :hash => user.change_password_hash, :user => user,
      :organization => organization
  end

  def changes_notification(users, options)
    subject I18n.t(:'notifier.changes_notification.title')
    recipients users.kind_of?(Array) ? users.map(&:email) : [users.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body :title => options[:title], :content => options[:content],
      :body => options[:body], :notification => options[:notification]
  end

  def conclusion_review_notification(user, conclusion_review, options = {})
    title = I18n.t(:'notifier.conclusion_review_notification.title',
      :review => conclusion_review.review.identification)
    elements = [
      "*#{Review.human_name} #{conclusion_review.review.identification}*"
    ]

    if options[:include_score_sheet]
      elements << "*#{I18n.t(:'conclusion_review.score_sheet')}*"
    end

    if options[:include_global_score_sheet]
      elements << "*#{I18n.t(:'conclusion_review.global_score_sheet')}*"
    end

    body_title = I18n.t(:'notifier.conclusion_review_notification.body_title',
      :elements => elements.to_sentence)

    subject title
    recipients [user.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    
    part :content_type => 'text/html', :body => render_message(
      'conclusion_review_notification', :conclusion_review => conclusion_review,
      :body_title => body_title,
      :note => options[:note],
      :notification => options[:notify] ?
        conclusion_review.create_notification_for(user) : nil)

    if File.exist?(conclusion_review.absolute_pdf_path)
      attachment :content_type => 'application/pdf',
        :filename => conclusion_review.pdf_name,
        :body => File.read(conclusion_review.absolute_pdf_path)
    end

    if options[:include_score_sheet] &&
        File.exist?(conclusion_review.review.absolute_score_sheet_path)
      attachment :content_type => 'application/pdf',
        :filename => conclusion_review.review.score_sheet_name,
        :body => File.read(conclusion_review.review.absolute_score_sheet_path)
    end

    if options[:include_global_score_sheet] &&
        File.exist?(conclusion_review.review.absolute_global_score_sheet_path)
      attachment :content_type => 'application/pdf',
        :filename => conclusion_review.review.global_score_sheet_name,
        :body => File.read(
          conclusion_review.review.absolute_global_score_sheet_path)
    end
  end

  def findings_expiration_warning(user, findings)
    subject I18n.t(:'notifier.findings_expiration_warning.title')
    recipients [user.email]
    from "\"#{I18n.t(:app_name)}\" <#{NOTIFICATIONS_EMAIL}>"
    sent_on Time.now
    content_type 'text/html'
    body :grouped_findings => findings.group_by(&:organization)
  end
end