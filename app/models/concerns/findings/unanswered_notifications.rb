module Findings::UnansweredNotifications
  extend ActiveSupport::Concern

  included do
    scope :unanswered, -> { where state: Finding::STATUS[:unanswered] }
    scope :unanswered_disregarded, -> {
      unanswered.finals(false).where notification_level: -1
    }
  end

  module ClassMethods
    def remember_users_about_unanswered
      unless DISABLE_FINDINGS_EXPIRATION_NOTIFICATION
        users = unanswered_disregarded.inject([]) do |u, finding|
          u | finding.users
        end

        users.each do |user|
          NotifierMailer.
            findings_unanswered_warning(user, user.findings.unanswered_disregarded.to_a).
            deliver_later
        end
      end
    end
  end
end
