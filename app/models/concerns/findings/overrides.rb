module Findings::Overrides
  extend ActiveSupport::Concern

  def <=>(other)
    other.kind_of?(Finding) ? id <=> other.id : -1
  end

  def to_s
    "#{review_code} - #{title} - #{control_objective_item.try(:review)}"
  end

  alias_method :label, :to_s
end
