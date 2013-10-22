module Reports::Period
  extend ActiveSupport::Concern

  def periods_for_interval
    Period.includes(:reviews => :conclusion_final_review).where(
      [
        "#{ConclusionFinalReview.table_name}.issue_date BETWEEN :from_date AND :to_date",
        "#{Period.table_name}.organization_id = :organization_id"
      ].join(' AND '),
      {
        :from_date => @from_date,
        :to_date => @to_date,
        :organization_id => @auth_organization.id
      }
    ).references(:reviews)
  end

  def periods_by_solution_date_for_interval(final = false)
    weaknesses = final ? :final_weaknesses : :weaknesses
    Period.includes(:reviews => [
        :conclusion_final_review, {:control_objective_items => weaknesses}]
    ).where(
      [
        "#{Weakness.table_name}.solution_date BETWEEN :from_date AND :to_date",
        "#{Period.table_name}.organization_id = :organization_id"
      ].join(' AND '),
      {
        :from_date => @from_date,
        :to_date => @to_date,
        :organization_id => @auth_organization.id
      }
    ).references(:reviews)
  end
end
