module Findings::Versions
  extend ActiveSupport::Concern

  def versions_between start_date = nil, end_date = nil
    conditions = []
    conditions << 'created_at >= :start' if start_date
    conditions << 'created_at <= :end'   if end_date

    versions.where conditions.join(' AND '), start: start_date, end: end_date
  end

  def versions_after_final_review end_date = nil
    versions_between final_review_created_at, end_date
  end

  def versions_before_final_review start_date = nil
    versions_between start_date, final_review_created_at
  end

  def final_review_created_at
    control_objective_item.try(:review).try(:conclusion_final_review).try :created_at
  end
end
