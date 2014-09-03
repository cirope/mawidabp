module Findings::Expiration
  extend ActiveSupport::Concern

  included do
    scope :next_to_expire, -> {
      where(
        final: false,
        state: Finding::STATUS[:being_implemented],
        follow_up_date: FINDING_WARNING_EXPIRE_DAYS.days.from_now_in_business.to_date
      )
    }
  end

  module ClassMethods
    def warning_users_about_expiration
      # Sólo si no es sábado o domingo (porque no tiene sentido)
      if [0, 6].exclude? Time.zone.today.wday
        users = next_to_expire.inject([]) do |u, finding|
          u | finding.users
        end

        users.each do |user|
          NotifierMailer.delay.findings_expiration_warning user, user.findings.next_to_expire.to_a
        end
      end
    end
  end
end
