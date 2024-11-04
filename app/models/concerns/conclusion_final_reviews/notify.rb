module ConclusionFinalReviews::Notify
  extend ActiveSupport::Concern

  module ClassMethods
    def notify_recent
      findings = Finding.joins(review: :conclusion_final_review).where(
        findings: { final: false }, conclusion_reviews: { created_at: 1.day.ago..}
      ).not_revoked

      users = findings.inject([]) do |u, finding|
        u | finding.users
      end

      users.each do |user|
        user_findings = findings.select { |finding| finding.users.include? user }

        NotifierMailer.notify_new_findings(user, user_findings).deliver_later
      end
    end
  end
end
