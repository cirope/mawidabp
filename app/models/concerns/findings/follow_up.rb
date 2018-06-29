module Findings::FollowUp
  extend ActiveSupport::Concern

  def stale?
    (being_implemented? || awaiting?) &&
      follow_up_date &&
      follow_up_date < Time.zone.today
  end

  def rescheduled?
    last_date = follow_up_date

    versions_scope = versions if final_review_created_at.blank?
    versions_scope ||= versions_after_final_review

    versions_scope.each do |v|
      # Reify busca el elemento original en la DB sin dup
      date = v.reify(dup: true)&.follow_up_date

      return true if date.present? && date != last_date
    end

    false
  end

  def all_follow_up_dates end_date = nil, reload = false
    @all_follow_up_dates = reload ? [] : (@all_follow_up_dates || [])
    last_date            = follow_up_date

    if @all_follow_up_dates.empty?
      dates = versions_after_final_review(end_date).map do |v|
        v.reify&.follow_up_date
      end

      dates.each do |d|
        if d.present? && d != last_date
          @all_follow_up_dates << last_date = d
        end
      end
    end

    @all_follow_up_dates.compact
  end
end
