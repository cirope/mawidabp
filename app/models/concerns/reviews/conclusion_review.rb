module Reviews::ConclusionReview
  extend ActiveSupport::Concern

  included do
    has_one :conclusion_draft_review, dependent: :destroy
    has_one :conclusion_final_review
  end

  def has_final_review?
    conclusion_final_review
  end

  def is_frozen?
    conclusion_final_review&.is_frozen?
  end
end
