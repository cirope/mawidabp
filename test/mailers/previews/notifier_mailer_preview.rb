# Preview all emails at http://localhost:3000/rails/mailers/notifier_mailer
class NotifierMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/pending_poll_email
  def pending_poll_email
    NotifierMailer.pending_poll_email Poll.take
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/group_welcome_email
  def group_welcome_email
    NotifierMailer.group_welcome_email Group.take
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/welcome_email
  def welcome_email
    NotifierMailer.welcome_email User.take
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/notify_new_findings
  def notify_new_findings
    # TODO: make the method avoid the creation of a Notification record
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/findings_briefs
  def findings_briefs
    user = User.includes(:findings).references(:findings).merge(Finding.with_pending_status).take
    findings = user.findings.with_pending_status.finals(false)

    NotifierMailer.findings_brief user, findings.to_a
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/notify_new_finding
  def notify_new_finding
    # TODO: make the method avoid the creation of a Notification record
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/notify_new_finding_answer
  def notify_new_finding_answer
    finding_answer = FindingAnswer.take
    users          = finding_answer.finding.users

    NotifierMailer.notify_new_finding_answer users, finding_answer
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/stale_notification
  def stale_notification
    user = User.joins(:notifications).merge(Notification.not_confirmed).take

    NotifierMailer.stale_notification user
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/unanswered_findings_notification
  def unanswered_findings_notification
    conditions = { state: Finding::STATUS[:unanswered] }
    user       = User.joins(:findings).merge(Finding.where(conditions)).take

    NotifierMailer.unanswered_findings_notification user, user.findings.where(conditions)
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/unanswered_finding_to_manager_notification
  def unanswered_finding_to_manager_notification
    conditions = { state: Finding::STATUS[:unanswered] }
    users      = User.joins(:findings).merge(Finding.where(conditions)).limit(1)
    finding    = users.take.findings.where(conditions).take

    NotifierMailer.unanswered_finding_to_manager_notification finding, users, 1
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/reassigned_findings_notification
  def reassigned_findings_notification
    new_users = User.last(2)
    old_users = User.joins(:findings).first(1)
    findings  = old_users.first.findings

    NotifierMailer.reassigned_findings_notification new_users, old_users, findings, false
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/restore_password
  def restore_password
    user         = User.where.not(change_password_hash: nil).take
    organization = user.organizations.take

    NotifierMailer.restore_password user, organization
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/changes_notification
  def changes_notification
    NotifierMailer.changes_notification(User.limit(2), {
      title:   'Email test title',
      content: 'Email test content',
      body:    'Email test body'
    })
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/conclusion_review_notification
  def conclusion_review_notification
    user              = User.joins(reviews: :conclusion_final_review).take
    review            = user.reviews.joins(:conclusion_final_review).take
    conclusion_review = review.conclusion_final_review
    organization      = review.organization

    conclusion_review.to_pdf

    NotifierMailer.conclusion_review_notification user, conclusion_review, organization_id: organization.id
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/findings_expiration_warning
  def findings_expiration_warning
    user = User.joins(:findings).take

    NotifierMailer.findings_expiration_warning user, user.findings.limit(3)
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/findings_expired_warning
  def findings_expired_warning
    user = User.joins(:findings).take

    NotifierMailer.findings_expired_warning user, user.findings.limit(3)
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/tasks_expiration_warning
  def tasks_expiration_warning
    user = User.joins(:tasks).take

    NotifierMailer.tasks_expiration_warning user, user.tasks.limit(3)
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/tasks_expired_warning
  def tasks_expired_warning
    user = User.joins(:tasks).take

    NotifierMailer.tasks_expired_warning user, user.tasks.limit(3)
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier_mailer/conclusion_final_review_close_date_warning
  def conclusion_final_review_close_date_warning
    user = User.joins(reviews: :conclusion_final_review).take
    cfrs = user.conclusion_final_reviews

    NotifierMailer.conclusion_final_review_close_date_warning user, cfrs
  end
end
