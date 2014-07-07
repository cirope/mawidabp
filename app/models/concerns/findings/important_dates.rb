module Findings::ImportantDates
  extend ActiveSupport::Concern

  def important_dates
    important_dates = []

    important_dates << notification_date_label if first_notification_date
    important_dates << confirmation_date_label if confirmation_date

    if (confirmed? || unconfirmed?) && expiration_diff.to_i > 0
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
        date: I18n.l(expiration_diff.days.from_now_in_business.to_date, format: :long)
      )
    end

    def expiration_diff
      if confirmation_date
        max_notification_date = stale_confirmed_days.days.ago_in_business.to_date

        confirmation_date.diff_in_business max_notification_date
      else
        max_notification_date = (FINDING_STALE_UNCONFIRMED_DAYS + stale_confirmed_days).days.ago_in_business.to_date

        first_notification_date.try :diff_in_business, max_notification_date
      end
    end
end
