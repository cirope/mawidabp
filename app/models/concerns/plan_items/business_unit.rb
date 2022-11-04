module PlanItems::BusinessUnit
  extend ActiveSupport::Concern

  def can_edit_business_unit?
    if persisted?
      PlanItem.list
              .left_joins(:memo, review: [:conclusion_final_review])
              .exists?(id: id, memos: { id: nil }, reviews: { conclusion_reviews: { id: nil } })
    else
      true
    end
  end
end
