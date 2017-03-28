# Preview all emails at http://localhost:3000/rails/mailers/notifier
class NotifierPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notifier/pending_poll_email
  def pending_poll_email
    Notifier.pending_poll_email Poll.take
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/group_welcome_email
  def group_welcome_email
    Notifier.group_welcome_email Group.take
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/welcome_email
  def welcome_email
    Notifier.welcome_email User.take
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/notify_new_findings
  def notify_new_findings
    # TODO: make the method avoid the creation of a Notification record
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/notify_new_finding
  def notify_new_finding
    # TODO: make the method avoid the creation of a Notification record
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/notify_new_finding_answer
  def notify_new_finding_answer
    finding_answer = FindingAnswer.take
    users          = finding_answer.finding.users

    Notifier.notify_new_finding_answer users, finding_answer
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/stale_notification
  def stale_notification
    user = User.joins(:notifications).merge(Notification.not_confirmed).take

    Notifier.stale_notification user
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/unanswered_findings_notification
  def unanswered_findings_notification
    conditions = { state: Finding::STATUS[:unanswered] }
    user       = User.joins(:findings).merge(Finding.where(conditions)).take

    Notifier.unanswered_findings_notification user, user.findings.where(conditions)
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/unanswered_finding_to_manager_notification
  def unanswered_finding_to_manager_notification
    conditions = { state: Finding::STATUS[:unanswered] }
    users      = User.joins(:findings).merge(Finding.where(conditions)).limit(1)
    finding    = users.take.findings.where(conditions).take

    Notifier.unanswered_finding_to_manager_notification finding, users, 1
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/reassigned_findings_notification
  def reassigned_findings_notification
    new_users = User.last(2)
    old_users = User.joins(:findings).first(1)
    findings  = old_users.first.findings

    Notifier.reassigned_findings_notification new_users, old_users, findings, false
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/restore_password
  def restore_password
    user         = User.where.not(change_password_hash: nil).take
    organization = user.organizations.take

    Notifier.restore_password user, organization
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/changes_notification
  def changes_notification
    Notifier.changes_notification(User.limit(2), {
      title:   'Email test title',
      content: 'Email test content',
      body:    'Email test body'
    })
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/conclusion_review_notification
  def conclusion_review_notification
    user              = User.joins(reviews: :conclusion_final_review).take
    review            = user.reviews.joins(:conclusion_final_review).take
    conclusion_review = review.conclusion_final_review

    conclusion_review.to_pdf

    Notifier.conclusion_review_notification user, conclusion_review
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/findings_expiration_warning
  def findings_expiration_warning
    user = User.joins(:findings).take

    Notifier.findings_expiration_warning user, user.findings.limit(3)
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/findings_expired_warning
  def findings_expired_warning
    user = User.joins(:findings).take

    Notifier.findings_expired_warning user, user.findings.limit(3)
  end

  # Preview this email at http://localhost:3000/rails/mailers/notifier/conclusion_final_review_close_date_warning
  def conclusion_final_review_close_date_warning
    user = User.joins(reviews: :conclusion_final_review).take
    cfrs = user.conclusion_final_reviews

    Notifier.conclusion_final_review_close_date_warning user, cfrs
  end
end
