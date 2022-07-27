module PlanItems::StatusCsvPat
  extend ActiveSupport::Concern

  def check_status
    if completed_early?
      'completed_early'
    elsif completed?
      'completed'
    elsif in_early_progress?
      'in_early_progress'
    elsif in_progress_no_delayed?
      'in_progress_no_delayed'
    elsif overdue?
      'overdue'
    elsif not_started_no_delayed?
      'not_started_no_delayed'
    elsif delayed_pat?
      'delayed_pat'
    end
  end

  def completed_early? on: Time.zone.today
    conclusion_final_review &&
      conclusion_final_review.issue_date < self.end && self.end >= on
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
    self.start <= on && self.end >= on
  end
end
