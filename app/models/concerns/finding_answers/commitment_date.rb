module FindingAnswers::CommitmentDate
  extend ActiveSupport::Concern

  def requires_commitment_date?
    has_date_required_status? &&
      has_follow_up_date_blank_or_expired? &&
      has_expired_commitment_date?
  end

  private

    def has_follow_up_date_blank_or_expired?
      finding.follow_up_date.blank? || finding.follow_up_date < Time.zone.today
    end

    def has_expired_commitment_date?
      last_commitment_date = finding.last_commitment_date

      last_commitment_date.blank? || last_commitment_date < Time.zone.today
    end
    
    def has_date_required_status?
      finding.being_implemented? ||
        finding.notify? ||
        finding.unconfirmed? ||
        finding.confirmed? ||
        finding.unanswered?
    end
end
