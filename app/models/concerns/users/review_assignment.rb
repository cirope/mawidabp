module Users::ReviewAssignment
  extend ActiveSupport::Concern

  def review_assignment_options
    options = {}
    types   = ReviewUserAssignment::TYPES

    options[:auditor]    = types[:auditor]    if auditor?
    options[:supervisor] = types[:supervisor] if supervisor?
    options[:manager]    = types[:manager]    if manager?
    options[:viewer]     = types[:viewer]     if committee?

    if can_act_as_audited?
      options[:audited] = types[:audited]
      options[:viewer]  = types[:viewer]
    end

    options
  end
end
