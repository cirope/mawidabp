module Weaknesses::Priority
  extend ActiveSupport::Concern

  def priority_text
    if REVIEW_MANUAL_SCORE
      Current.organization.priorities_text_for date: created_at, value: priority
    else
      priority = self.class.priorities.detect { |p| p.last == self.priority }

      priority ? I18n.t("priority_types.#{priority.first}") : ''
    end
  end
end
