module ConclusionFinalReviews::Destroy
  extend ActiveSupport::Concern

  included do
    before_destroy :check_if_can_be_destroyed, :undo_final_findings
  end

  def can_be_destroyed?
    ALLOW_CONCLUSION_FINAL_REVIEW_DESTRUCTION &&
      review.weaknesses.all? { |w| w.repeated_of.blank? }
  end

  private

    def check_if_can_be_destroyed
      throw :abort unless can_be_destroyed?
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
