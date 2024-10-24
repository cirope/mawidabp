module ConclusionFinalReviews::Destroy
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed, :undo_final_findings, prepend: true
  end

  def can_be_destroyed?
    within_allowed_deletion_period? &&
      has_not_repeated_in_weakness? &&
      has_not_a_review_as_external_review?
  end

  private

    def within_allowed_deletion_period?
      ALLOW_CONCLUSION_FINAL_REVIEW_DESTRUCTION_DAYS > 0 &&
        created_at >= ALLOW_CONCLUSION_FINAL_REVIEW_DESTRUCTION_DAYS.days.ago
    end

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

        finding.work_papers.each { |wp| wp.update_column :file_model_id, nil }

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
