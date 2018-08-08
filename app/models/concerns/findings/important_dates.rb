module Findings::ImportantDates
  extend ActiveSupport::Concern

  def important_dates
    important_dates = []

    important_dates << notification_date_label if first_notification_date
    important_dates << confirmation_date_label if confirmation_date

    if (confirmed? || unconfirmed?) && expiration_date
      important_dates << expiration_date_label
    end

    important_dates
  end

  private

    def notification_date_label
      I18n.t(
        'finding.important_dates.notification_date',
        date: I18n.l(first_notification_date, format: :long)
      )
    end

    def confirmation_date_label
      I18n.t(
        'finding.important_dates.confirmation_date',
        date: I18n.l(confirmation_date, format: :long)
      )
    end

    def expiration_date_label
      I18n.t(
        'finding.important_dates.expiration_date',
        date: I18n.l(expiration_date, format: :long)
      )
    end

    def expiration_date
      if first_notification_date && stale_confirmed_days > 0
        stale_confirmed_days.business_days.after(first_notification_date)
      end
    end
end
