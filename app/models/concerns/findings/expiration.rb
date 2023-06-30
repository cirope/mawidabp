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
    def next_to_expire setting
      expires_on setting.business_days.from_now.to_date
    end

    def warning_users_about_expiration
      # Sólo si no es sábado o domingo (porque no tiene sentido)
      if Time.zone.today.workday?
        finding_warning_expire_days_parameters.each do |organization, value|
          Current.organization = organization
          Current.group        = organization.group
          expire_days          = value.split ','
          users                = []

          expire_days.map do |day|
            users = list.next_to_expire(day.to_i).inject(users) do |u, finding|
              u | finding.users
            end

            users.each do |user|
              findings = []

              expire_days.each do |day|
                byebug
                findings = user.findings.list.next_to_expire(day.to_i)
              end
byebug
              #NotifierMailer.findings_expiration_warning(user, findings.to_a).deliver_later
            end
          end
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

        being_implemented.or(awaiting).finals(false).where follow_up_date: from..to
      end

      def expires_to_date date
        date = date.next until date.next.workday?

        date
      end

      def finding_warning_expire_days_parameters
        Organization.all_parameters('finding_warning_expire_days').map do |p|
          [p[:organization], p[:parameter]]
        end
      end
  end
end
