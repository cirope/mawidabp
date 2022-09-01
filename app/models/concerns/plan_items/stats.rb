module PlanItems::Stats
  extend ActiveSupport::Concern

  def excluded_from_stats?
    PLAN_ITEM_STATS_EXCLUDED_SCOPES.include? scope
  end
end
