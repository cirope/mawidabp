module Tasks::Expiration
  extend ActiveSupport::Concern

  included do
    scope :expired, -> {
      pending.or(in_progress).finals(false).where(
        "#{quoted_table_name}.#{qcn 'due_on'} < ?", Time.zone.today
      )
    }
  end

  def expired?
    (pending? || in_progress?) && due_on < Time.zone.today
  end

  module ClassMethods
    def expire_date expire_day
      expire_day.business_days.from_now.to_date
    end

    def finals final
      includes(:finding).merge(Finding.list.finals(final)).references :findings
    end

    def warning_users_about_expiration
      # Sólo si no es sábado o domingo (porque no tiene sentido)
      if Time.zone.today.workday?
        finding_warning_expire_days_parameters.each do |organization, value|
          Current.organization = organization
          Current.group        = organization.group
          expire_days          = value.to_s.split(',').map { |v| v.strip.to_i }

          expire_dates = expire_days.map do |day|
            expire_date(day) if day > 0
          end

          if expire_dates.present?
            users = expires_on(expire_dates).inject([]) do |u, task|
              u | task.users
            end

            users.each do |user|
              tasks = user.tasks.expires_on expire_dates

              NotifierMailer.tasks_expiration_warning(user, tasks.to_a).deliver_later
            end
          end
        end
      end
    end

    def remember_users_about_expiration
      users = expired.inject([]) do |u, task|
        u | task.users
      end

      users.each do |user|
        NotifierMailer.
          tasks_expired_warning(user, user.tasks.expired.to_a).
          deliver_later
      end
    end

    def expires_on dates
      dates.map do |from|
        to = expires_to_date from

        where due_on: from..to
      end.
        inject(:or).
        finals(:false).
        pending_statuses
    end

    def pending_statuses
      pending.or in_progress
    end

    private
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
