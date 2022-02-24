module Findings::SuggestionAddDaysFollowUpDate
  extend ActiveSupport::Concern

  def suggestion_to_add_days_follow_up_date_depending_on_the_risk
    {
      0 => 180,
      1 => 365,
      2 => 270,
      3 => 180
    }
  end

  def states_that_suggest_follow_up_date
    [Finding::STATUS[:being_implemented], Finding::STATUS[:awaiting]]
  end
end
