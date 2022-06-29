module PlanItems::StatusCsvPat
  extend ActiveSupport::Concern

  def completed? on: Time.zone.today
    conclusion_final_review &&
      conclusion_final_review.created_at >= self.end && self.end >= on
  end

  def completed_early? on: Time.zone.today
    conclusion_final_review &&
      conclusion_final_review.created_at < self.end && self.end < on
  end

  def in_early_progress?
    review && review.created_at < self.start
  end

  def not_started_no_delayed? on: Time.zone.today
    review.nil? && self.start < on
  end

  def in_progress_no_delayed?
    review && self.start == review.created_at
  end

  def delayed? on: Time.zone.today
    review.nil? && self.start > on
  end

  def overdue? on: Time.zone.today
    conclusion_final_review.nil? && self.end > on
  end
end
