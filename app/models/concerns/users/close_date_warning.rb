module Users::CloseDateWarning
  extend ActiveSupport::Concern

  module ClassMethods
    def notify_auditors_about_close_date
      if Time.zone.today.workday?
        all_with_conclusion_final_reviews_for_notification.find_each do |user|
          cfrs = user.conclusion_final_reviews.with_near_close_date.to_a

          NotifierMailer.conclusion_final_review_close_date_warning(user, cfrs).deliver_later
        end
      end
    end

    def notify_new_findings
      if Time.zone.today.workday?
        users, findings = [], []

        all_with_findings_for_notification.each do |user|
          users << user

          findings |= user.findings.for_notification
        end

        Finding.transaction do
          raise ActiveRecord::Rollback unless findings.all? &:mark_as_unconfirmed
        end

        if CHECK_FINDING_EMAIL_REPLIES
          users.each do |user|
            user.findings.recently_notified.each do |finding|
              NotifierMailer.notify_new_finding(user, finding).deliver_later
            end
          end
        else
          users.each do |user|
            findings = user.findings.recently_notified.to_a

            NotifierMailer.notify_new_findings(user, findings).deliver_later
          end
        end
      end
    end
  end
end
