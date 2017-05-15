module FindingAnswers::Notifications
  extend ActiveSupport::Concern

  included do
    after_commit :send_notification_to_users

    attr_accessor :notify_users
  end

  private

    def send_notification_to_users
      if notify_users == true || notify_users == '1'
        users = finding.users - [user]

        if users.present? && answer.present?
          Notifier.notify_new_finding_answer(users, self).deliver_later
        end
      end
    end
end
