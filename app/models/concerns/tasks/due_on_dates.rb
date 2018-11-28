module Tasks::DueOnDates
  extend ActiveSupport::Concern

  def rescheduled?
    last_date = due_on

    versions_after_final_review.any? do |v|
      date = v.reify(dup: true)&.due_on

      date.present? && date != due_on
    end
  end

  def all_due_on_dates
    all_due_on_dates = []
    last_date        = due_on

    versions_after_final_review.each do |v|
      d = v.reify(dup: true)&.due_on

      all_due_on_dates << last_date = d if d.present? && d != last_date
    end

    all_due_on_dates.compact
  end

  private

    def versions_after_final_review
      start = finding.final_review_created_at

      if start
        versions.where('created_at >= ?', start)
      else
        versions.none
      end
    end
end
