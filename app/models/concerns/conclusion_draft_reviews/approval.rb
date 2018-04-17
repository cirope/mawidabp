module ConclusionDraftReviews::Approval
  extend ActiveSupport::Concern

  included do
    before_save :check_for_approval

    attr_accessor :force_approval
  end

  def check_for_approval
    self.approved = review && (
      review.is_approved? ||
      (force_approval? && review.can_be_approved_by_force)
    )

    true
  end

  def force_approval?
    force_approval == true || force_approval == '1'
  end
end
