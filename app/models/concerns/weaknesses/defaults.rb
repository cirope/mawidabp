module Weaknesses::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_review_code, if: :new_record?
    after_initialize :set_priority, unless: -> { HIDE_WEAKNESSES_PRIORITY }
  end

  private

    def set_review_code
      self.review_code ||= next_code
    end

    def set_priority
      self.priority ||= self.class.priorities_values.first
    end
end
