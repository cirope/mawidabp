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

    def finals final
      includes(:finding).merge(Finding.finals(final)).references :findings
    end

    def warning_users_about_expiration
      # Sólo si no es sábado o domingo (porque no tiene sentido)
      if Time.zone.today.workday?
        finding_warning_expire_days_parameters.each do |organization, value|

          Current.organization = organization
          Current.group        = organization.group
          expire_days          = value.to_s.split ','

          expire_dates = expire_days.map do |day|
            expire_date(day.to_i) if day.to_i > 0
          end

          if expire_dates.present?
            users = list.expires_on(expire_dates).finals(:false).expires_statuses.inject([]) do |u, task|
              u | task.users
            end

            users.each do |user|
              tasks = user.tasks.list.expires_on(expire_dates).finals(:false).expires_statuses

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

    def expires_on date
      dates.map do |from|
        to = expires_to_date from

        where due_on: from..to
      end.inject(:or)

      pending.or(in_progress)
    end

    def expires_statuses
      pending.or(in_progress)
    end

    private
      def expires_to_date date
        date.next until date.next.workday?
      end

      def finding_warning_expire_days_parameters
        Organization.all_parameters('finding_warning_expire_days').map do |p|
          [p[:organization], p[:parameter]]
        end
      end
  end
end
