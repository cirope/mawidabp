module PlanItems::Status
  extend ActiveSupport::Concern

  def status_text long = true
    i18n_prefix = 'plans.item_status'
    size        = long ? 'long' : 'short'

    if concluded?
      I18n.t "#{i18n_prefix}.concluded.#{size}"
    elsif executed? && on_time?
      I18n.t "#{i18n_prefix}.executing_in_time.#{size}"
    elsif executed?
      I18n.t "#{i18n_prefix}.executing_overtime.#{size}"
    elsif should_have_started?
      I18n.t "#{i18n_prefix}.delayed.#{size}"
    end
  end

  def status_color
    if concluded?
      'text-success'
    elsif executed? && on_time?
      'text-muted'
    elsif executed?
      'text-warning'
    elsif should_have_started?
      'text-danger'
    end
  end

  def concluded? on: Time.zone.today
    review&.has_final_review? && review.conclusion_final_review.created_at <= on
  end

  def executed? on: Time.zone.today
    review && review.created_at <= on
  end

  def on_time? on: Time.zone.today
    self.end >= on
  end

  def should_have_started? on: Time.zone.today
    business_unit && start && start < on
  end
end
