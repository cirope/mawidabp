module Users::ReviewAssignment
  extend ActiveSupport::Concern

  def review_assignment_options
    options = {}
    types   = ReviewUserAssignment::TYPES

    options[:viewer]      = types[:viewer]      if committee?
    options[:auditor]     = types[:auditor]     if auditor?
    options[:supervisor]  = types[:supervisor]  if supervisor?
    options[:manager]     = types[:manager]     if manager?

    if can_act_as_audited?
      options[:audited] = types[:audited]
      options[:viewer]  = types[:viewer]
    end

    if (supervisor? || manager?) && Current.conclusion_pdf_format != 'gal'
      options[:responsible] = types[:responsible]
    end

    options
  end
end
