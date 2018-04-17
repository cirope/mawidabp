module PlanItems::Status
  extend ActiveSupport::Concern

  def status_text long: true, on: Time.zone.today
    i18n_prefix = 'plans.item_status'
    size        = long ? 'long' : 'short'

    if concluded? on: on
      I18n.t "#{i18n_prefix}.concluded.#{size}"
    elsif executed?(on: on) && on_time?(on: on)
      I18n.t "#{i18n_prefix}.executing_in_time.#{size}"
    elsif executed? on: on
      I18n.t "#{i18n_prefix}.executing_overtime.#{size}"
    elsif should_have_started? on: on
      I18n.t "#{i18n_prefix}.delayed.#{size}"
    end
  end

  def status_color on: Time.zone.today
    if concluded? on: on
      'text-success'
    elsif executed?(on: on) && on_time?(on: on)
      'text-muted'
    elsif executed? on: on
      'text-warning'
    elsif should_have_started? on: on
      'text-danger'
    end
  end

  def concluded? on: Time.zone.today
    conclusion_final_review &&
      conclusion_final_review.send(PLAN_ITEM_REVIEW_CONCLUDED_ON).to_date <= on
  end

  def executed? on: Time.zone.today
    review && review.created_at.to_date <= on
  end

  def on_time? on: Time.zone.today
    self.end >= on
  end

  def should_have_started? on: Time.zone.today
    business_unit && start && start < on
  end
end
