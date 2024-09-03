module PlanItems::Progress
  extend ActiveSupport::Concern

  def progress
    if concluded?
      human_units
    elsif executed?
      if human_units_consumed >= human_units
        human_units
      else
        human_units_consumed
      end
    else
      0
    end
  end
end
