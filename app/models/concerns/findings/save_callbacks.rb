module Findings::SaveCallbacks
  extend ActiveSupport::Concern

  included do
    before_save :recalculate_review_score
  end

  private

    def recalculate_review_score
      # Since score gets refreshed on review before save we just need to save =)
      review.save!
    rescue ActiveRecord::RecordInvalid
      throw :abort
    end
end
