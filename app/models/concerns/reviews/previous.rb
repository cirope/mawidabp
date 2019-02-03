module Reviews::Previous
  extend ActiveSupport::Concern

  def previous
    issue_date_column = [
      ConclusionFinalReview.quoted_table_name,
      ConclusionFinalReview.qcn('issue_date')
    ].join '.'

    self.class.list_with_final_review.
      includes(:plan_item).
      references(:plan_items, :conclusion_reviews).
      where(plan_items: { business_unit_id: plan_item.business_unit_id }).
      where("#{issue_date_column} < ?", pretended_issue_date).
      where.not(id: id).
      order(issue_date_column).
      last
  end

  private

    def pretended_issue_date
      conclusion_final_review&.issue_date   ||
        conclusion_draft_review&.issue_date ||
        Time.zone.today
    end
end
