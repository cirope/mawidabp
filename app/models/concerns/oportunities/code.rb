module Oportunities::Code
  extend ActiveSupport::Concern

  def prefix
    I18n.t 'code_prefixes.oportunities'
  end

  def next_code review = nil
    review ||= control_objective_item&.review

    review ? review.next_oportunity_code(prefix) : "#{prefix}1".strip
  end
end
