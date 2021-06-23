module Reviews::Previous
  extend ActiveSupport::Concern

  def previous
    direct_prev   = previous_by_business_unit
    indirect_prev = previous_by_shared_business_unit

    if direct_prev.blank? && indirect_prev
      indirect_prev
    elsif indirect_prev.blank? && direct_prev
      direct_prev
    elsif direct_prev.present? && direct_prev.issue_date <= indirect_prev.issue_date
      direct_prev
    else
      indirect_prev
    end
  end

  private

    def previous_by_business_unit business_unit_id = nil
      business_unit_id ||= plan_item.business_unit_id
      issue_date_column  = [
        ConclusionFinalReview.quoted_table_name,
        ConclusionFinalReview.qcn('issue_date')
      ].join '.'

      self.class.list_with_final_review.
        includes(:plan_item).
        references(:plan_items, :conclusion_reviews).
        where(plan_items: { business_unit_id: business_unit_id }).
        where("#{issue_date_column} < ?", pretended_issue_date).
        where.not(id: id).
        order(Arel.sql issue_date_column).
        last
    end

    def previous_by_shared_business_unit
      business_unit = BusinessUnit.list.joins(:business_unit_type).where(
        name:                plan_item.business_unit.name,
        business_unit_types: { shared_business_units: true }
      ).take

      previous_by_business_unit business_unit.id if business_unit
    end

    def pretended_issue_date
      conclusion_final_review&.issue_date   ||
        conclusion_draft_review&.issue_date ||
        Time.zone.today
    end
end
