module Tasks::DueOnDates
  extend ActiveSupport::Concern

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
