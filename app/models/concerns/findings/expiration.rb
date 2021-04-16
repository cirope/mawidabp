module Findings::Expiration
  extend ActiveSupport::Concern

  included do
    scope :expired, -> {
      being_implemented.or(awaiting).finals(false).where(
        "#{quoted_table_name}.#{qcn 'follow_up_date'} < ?", Time.zone.today
      )
    }
  end

  module ClassMethods
    def expires_very_soon
      date = if Time.zone.now < Time.zone.now.noon
               Time.zone.today
             else
               1.business_day.from_now.to_date
             end

      expires_on date
    end

    def next_to_expire
      expires_on FINDING_WARNING_EXPIRE_DAYS.business_days.from_now.to_date
    end

    def warning_users_about_expiration
      # Sólo si no es sábado o domingo (porque no tiene sentido)
      if Time.zone.today.workday?
        users = next_to_expire.or(expires_very_soon).inject([]) do |u, finding|
          u | finding.users
        end

        users.each do |user|
          findings = user.findings.next_to_expire.or user.findings.expires_very_soon

          NotifierMailer.findings_expiration_warning(user, findings.to_a).deliver_later
        end
      end
    end

    def remember_users_about_expiration
      unless DISABLE_FINDINGS_EXPIRATION_NOTIFICATION
        users = expired.inject([]) do |u, finding|
          u | finding.users
        end

        users.each do |user|
          NotifierMailer.
            findings_expired_warning(user, user.findings.expired.to_a).
            deliver_later
        end
      end
    end

    private

      def expires_on date
        from = date
        to   = expires_to_date from

        being_implemented.(awaiting).finals(false).where follow_up_date: from..to
      end

      def expires_to_date date
        date = date.next until date.next.workday?

        date
      end
  end
end
