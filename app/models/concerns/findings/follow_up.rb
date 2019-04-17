module Findings::FollowUp
  extend ActiveSupport::Concern

  def stale?
    (being_implemented? || awaiting?) &&
      follow_up_date &&
      follow_up_date < Time.zone.today
  end

  def all_follow_up_dates end_date = nil, reload = false
    @all_follow_up_dates = reload ? [] : (@all_follow_up_dates || [])
    last_date            = follow_up_date

    if @all_follow_up_dates.empty?
      dates = versions_after_final_review(end_date).map do |v|
        v.reify&.follow_up_date
      end

      dates.reverse.each do |d|
        if d.present? && d < last_date
          @all_follow_up_dates << last_date = d
        end
      end
    end

    @all_follow_up_dates.compact
  end
end
