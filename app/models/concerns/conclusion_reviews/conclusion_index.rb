module ConclusionReviews::ConclusionIndex
  extend ActiveSupport::Concern

  included do
    before_save :set_conclusion_index
  end

  private

    def set_conclusion_index
      if SHOW_CONCLUSION_AS_OPTIONS && conclusion_changed?
        self.conclusion_index = CONCLUSION_OPTIONS.index conclusion
      end
    end
end
