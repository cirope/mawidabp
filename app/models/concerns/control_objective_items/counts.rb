module ControlObjectiveItems::Counts
  extend ActiveSupport::Concern

  def show_counts? prefix
    ORGANIZATIONS_WITH_CONTROL_OBJECTIVE_COUNTS.include?(prefix) ||
      review.business_unit_type.require_counts?
  end
end
