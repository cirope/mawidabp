module Findings::Expiration
  extend ActiveSupport::Concern

  included do
    scope :expired, -> {
      finals(false).being_implemented.where(
        "#{quoted_table_name}.#{qcn 'follow_up_date'} < ?", Time.zone.today
      )
    }
  end

  module ClassMethods
    def expires_now
      expires_on Time.zone.today
    end

    def next_to_expire
      expires_on FINDING_WARNING_EXPIRE_DAYS.days.from_now_in_business.to_date
    end

    def warning_users_about_expiration
      # Sólo si no es sábado o domingo (porque no tiene sentido)
      if [0, 6].exclude? Time.zone.today.wday
        users = next_to_expire.or(expires_now).inject([]) do |u, finding|
          u | finding.users
        end

        users.each do |user|
          findings = user.findings.next_to_expire.or user.findings.expires_now

          NotifierMailer.findings_expiration_warning(user, findings.to_a).deliver_later
        end
      end
    end

    def remember_users_about_expiration
      users = expired.inject([]) do |u, finding|
        u | finding.users
      end

      users.each do |user|
        NotifierMailer.findings_expired_warning(user, user.findings.expired.to_a).deliver_later
      end
    end

    private

      def expires_on date
        from = date
        to   = from.wday == 5 ? from + 2.days : from

        finals(false).being_implemented.where follow_up_date: from..to
      end
  end
end
