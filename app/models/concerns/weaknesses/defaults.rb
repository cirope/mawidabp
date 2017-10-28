module Weaknesses::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_review_code, if: :new_record?
    after_initialize :set_priority, if: -> { HIDE_WEAKNESS_PRIORITY }
    after_initialize :set_progress, if: -> { SHOW_WEAKNESS_PROGRESS }
  end

  private

    def set_review_code
      self.review_code ||= next_code
    end

    def set_priority
      self.priority ||= self.class.priorities_values.first
    end

    def set_progress
      self.progress ||= 0
    end
end
