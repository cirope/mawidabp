module PlanItems::StatusCsvPat
  extend ActiveSupport::Concern

  def completed_early? on: Time.zone.today
    conclusion_final_review &&
      conclusion_final_review.issue_date < self.end && self.end > on
  end

  def completed?
    conclusion_final_review
  end

  def in_early_progress? on: Time.zone.today
    review && self.start > on
  end

  def in_progress_no_delayed? on: Time.zone.today
    review && self.start <= on && self.end >= on
  end

  def overdue? on: Time.zone.today
    self.start <= on && self.end < on
  end

  def not_started_no_delayed? on: Time.zone.today
    self.start > on && self.end >= on
  end

  def delayed_pat? on: Time.zone.today
    self.start <= on && self.end > on
  end
end
