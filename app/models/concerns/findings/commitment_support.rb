module Findings::CommitmentSupport
  extend ActiveSupport::Concern

  def require_commitment_support? commitment_date
    FINDING_ANSWER_COMMITMENT_SUPPORT  &&
      commitment_date.future?          &&
      being_implemented?               &&
      follow_up_date.present?          &&
      follow_up_date < commitment_date
  end
end
