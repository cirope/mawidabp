module Tasks::DueOnDates
  extend ActiveSupport::Concern

  def rescheduled?
    last_date = due_on

    versions.any? do |v|
      date = v.reify(dup: true)&.due_on

      date.present? && date != due_on
    end
  end

  def all_due_on_dates
    all_due_on_dates = []
    last_date        = due_on
    dates            = versions.map { |v| v.reify(dup: true)&.due_on }

    dates.each do |d|
      all_due_on_dates << last_date = d if d.present? && d != last_date
    end

    all_due_on_dates.compact
  end
end
