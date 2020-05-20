module FindingAnswers::Endorsements
  extend ActiveSupport::Concern

  included do
    has_many :endorsements, dependent: :destroy, inverse_of: :finding_answer

    accepts_nested_attributes_for :endorsements, allow_destroy: true, reject_if: :all_blank
  end

  def commitment_date_status
    if endorsements.all?(&:approved?)
      'approved'
    elsif endorsements.all?(&:pending?)
      'pending'
    else
      'rejected'
    end
  end
end
