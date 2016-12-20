module PlanItems::Status
  extend ActiveSupport::Concern

  def status_text long = true
    if review&.has_final_review?
      I18n.t("plan.item_status.concluded.#{long ? :long : :short}")
    elsif review
      if self.end >= Date.today
        I18n.t("plan.item_status.executing_in_time.#{long ? :long : :short}")
      else
        I18n.t("plan.item_status.executing_overtime.#{long ? :long : :short}")
      end
    elsif !review && business_unit
      if start && start < Date.today
        I18n.t("plan.item_status.delayed.#{long ? :long : :short}")
      end
    end
  end

  def status_color
    if review&.has_final_review?
      'text-success'
    elsif review
      if self.end >= Date.today
        'text-muted'
      else
        'text-warning'
      end
    elsif !review && business_unit
      if start && start < Date.today
        'text-danger'
      end
    end
  end
end
