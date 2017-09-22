module Weaknesses::Code
  extend ActiveSupport::Concern

  def prefix
    I18n.t 'code_prefixes.weaknesses'
  end

  def next_code review = nil
    review ||= control_objective_item&.review

    review ? review.next_weakness_code(prefix) : "#{prefix}1".strip
  end
end
