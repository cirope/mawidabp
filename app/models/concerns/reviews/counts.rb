module Reviews::Counts
  extend ActiveSupport::Concern

  def show_counts? prefix
    control_objective_items.any? { |coi| coi.show_counts? prefix }
  end
end
