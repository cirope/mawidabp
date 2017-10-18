module Weaknesses::Priority
  extend ActiveSupport::Concern

  def priority_text
    priority = self.class.priorities.detect { |p| p.last == self.priority }

    priority ? I18n.t("priority_types.#{priority.first}") : ''
  end
end
