module Findings::CommitmentSupport
  extend ActiveSupport::Concern

  def require_commitment_support? commitment_date
    # TODO: remove "weak" logic when customer ask for
    case FINDING_ANSWER_COMMITMENT_SUPPORT
    when 'weak'
      being_implemented?       &&
      follow_up_date.present?  &&
      commitment_date.present?
    when 'true'
      commitment_date.future?          &&
      being_implemented?               &&
      follow_up_date.present?          &&
      follow_up_date < commitment_date
    end
  end

  module ClassMethods
    def show_commitment_support?
      %w(true weak).include? FINDING_ANSWER_COMMITMENT_SUPPORT
    end
  end
end
