module Findings::Expiration
  extend ActiveSupport::Concern

  included do
    scope :next_to_expire, -> {
      date = FINDING_WARNING_EXPIRE_DAYS.days.from_now_in_business.to_date

      finals(false).being_implemented.where follow_up_date: date
    }
    scope :expires_today, -> {
      finals(false).being_implemented.where follow_up_date: Time.zone.today
    }
    scope :expired, -> {
      finals(false).being_implemented.where(
        "#{quoted_table_name}.#{qcn 'follow_up_date'} < ?", Time.zone.today
      )
    }
  end

  module ClassMethods
    def warning_users_about_expiration
      # Sólo si no es sábado o domingo (porque no tiene sentido)
      if [0, 6].exclude? Time.zone.today.wday
        users = next_to_expire.or(expires_today).inject([]) do |u, finding|
          u | finding.users
        end

        users.each do |user|
          findings = user.findings.next_to_expire.or user.findings.expires_today

          Notifier.findings_expiration_warning(user, findings.to_a).deliver_later
        end
      end
    end

    def remember_users_about_expiration
      users = expired.inject([]) do |u, finding|
        u | finding.users
      end

      users.each do |user|
        Notifier.findings_expired_warning(user, user.findings.expired.to_a).deliver_later
      end
    end
  end
end
