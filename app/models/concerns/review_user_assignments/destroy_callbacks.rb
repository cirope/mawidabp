module ReviewUserAssignments::DestroyCallbacks
  extend ActiveSupport::Concern

  included do
    before_destroy :try_delete_user_in_all_review_findings
  end

  private

    def try_delete_user_in_all_review_findings
      findings = user.findings.all_for_reallocation_with_review review

      findings.each do |finding|
        fua = finding.finding_user_assignments.detect do |fua|
          fua.user_id == user.id
        end

        fua.mark_for_destruction
        finding.avoid_changes_notification = true
        finding.save # Try, if it is invalid does not matter
      end

      notify_responsibility_removed
    end

    def notify_responsibility_removed
      if !@cancel_notification && (review.oportunities | review.weaknesses).size > 0
        title = I18n.t 'review_user_assignment.responsibility_removed',
          review: review.identification

        NotifierMailer.changes_notification(
          user, title: title, organizations: [review.organization]
        ).deliver_later
      end
    end
end
