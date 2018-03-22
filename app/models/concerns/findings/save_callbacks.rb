module Findings::SaveCallbacks
  extend ActiveSupport::Concern

  included do
    before_save :recalculate_review_score
  end

  private

    def recalculate_review_score
      # Since score gets refreshed on review before save we just need to save =)
      review.save!
    rescue ActiveRecord::StaleObjectError
      review.reload.save!
    rescue ActiveRecord::RecordInvalid
      errors.add :base, 'Review can not be saved!'

      throw :abort
    end
end
