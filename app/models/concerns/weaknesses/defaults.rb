module Weaknesses::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_review_code, if: :new_record?
    after_initialize :set_progress, if: -> { SHOW_WEAKNESS_PROGRESS }
    before_validation :set_priority, if: -> { SHOW_CONDENSED_PRIORITIES }
  end

  private

    def set_review_code
      self.review_code ||= next_code
    end

    def set_progress
      self.progress ||= 0
    end

    def set_priority
      unless risk == Finding.risks[:medium]
        self.priority = Finding.priorities[:low]
      end
    end
end
