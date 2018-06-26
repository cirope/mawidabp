module ConclusionFinalReviews::Defaults
  extend ActiveSupport::Concern

  included do
    attr_accessor :import_from_draft

    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      if import_from_draft && self.review
        draft = ConclusionDraftReview.where(review_id: self.review_id).first

        self.attributes = draft.attributes if draft
      end
    end
end
