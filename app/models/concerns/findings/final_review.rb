module Findings::FinalReview
  extend ActiveSupport::Concern

  def check_for_final_review(_)
    if !marked_for_destruction? && final? && review&.is_frozen?
      raise 'Conclusion Final Review frozen'
    end
  end

  def issue_date
    review&.conclusion_final_review&.issue_date
  end

  module ClassMethods
    def notify_recently_finalized
      findings = joins(
        organization: :settings,
        review:       :conclusion_final_review
      ).where(
        findings:           { final: false            },
        conclusion_reviews: { created_at: 1.day.ago.. },
        settings:           {
                              name: 'notify_recently_finalized_findings',
                              value: '1'
                            }
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
