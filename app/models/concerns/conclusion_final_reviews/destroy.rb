module ConclusionFinalReviews::Destroy
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed, :undo_final_findings, prepend: true
  end

  def can_be_destroyed?
    ALLOW_CONCLUSION_FINAL_REVIEW_DESTRUCTION &&
      has_not_repeated_in_weakness? &&
      has_not_a_review_as_external_review?
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
    end

    def has_not_repeated_in_weakness?
      review.weaknesses.none?(&:repeated?)
    end

    def has_not_a_review_as_external_review?
      is_nbc? ? ExternalReview.where(alternative_review_id: review.id).blank? : true
    end

    def undo_final_findings
      final_findings = review.final_weaknesses.not_revoked +
                       review.final_oportunities.not_revoked

      final_findings.each do |finding|
        def finding.can_be_destroyed?; true; end

        finding.mark_for_destruction
        finding.destroy!
      end

      revoked_findings = review.final_weaknesses.revoked +
                         review.final_oportunities.revoked

      revoked_findings.each do |rf|
        rf.final = false
        rf.save! validate: false
      end
    end
end
