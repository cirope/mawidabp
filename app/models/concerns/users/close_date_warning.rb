module Users::CloseDateWarning
  extend ActiveSupport::Concern

  module ClassMethods
    def notify_auditors_about_close_date
      if [0, 6].exclude? Date.today.wday
        all_with_conclusion_final_reviews_for_notification.find_each do |user|
          cfrs = user.conclusion_final_reviews.with_near_close_date.to_a

          Notifier.conclusion_final_review_close_date_warning(user, cfrs).deliver_later
        end
      end
    end

    def notify_new_findings
      unless [0, 6].include?(Date.today.wday)
        users, findings = [], []

        all_with_findings_for_notification.each do |user|
          users << user

          findings |= user.findings.for_notification
        end

        Finding.transaction do
          raise ActiveRecord::Rollback unless findings.all? &:mark_as_unconfirmed
        end

        users.each { |user| Notifier.notify_new_findings(user).deliver_later }
      end
    end
  end
end
