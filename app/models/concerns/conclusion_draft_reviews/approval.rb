module ConclusionDraftReviews::Approval
  extend ActiveSupport::Concern

  included do
    before_save :check_for_approval

    attr_reader   :approval_errors
    attr_accessor :force_approval
  end

  def must_be_approved?
    errors = []

    if corrective_actions.blank? && validate_short_alternative_pdf_attributes?
      errors << I18n.t('conclusion_draft_review.errors.without_corrective_actions')
    end

    (@approval_errors = errors).blank?
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
