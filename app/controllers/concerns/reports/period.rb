module Reports::Period
  def periods_for_interval
    Period.list.includes(:reviews => :conclusion_final_review).where(
      "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn('issue_date')} BETWEEN :from_date AND :to_date",
      { :from_date => @from_date, :to_date => @to_date }
    ).references(:reviews)
  end

  def periods_by_solution_date_for_interval(final = false)
    weaknesses = final ? :final_weaknesses : :weaknesses
    Period.list.includes(
      :reviews => [
        :conclusion_final_review, { :control_objective_items => weaknesses }
      ]
    ).where(
      "#{Weakness.quoted_table_name}.#{Weakness.qcn('solution_date')} BETWEEN :from_date AND :to_date",
      { :from_date => @from_date, :to_date => @to_date }
    ).references(:reviews)
  end
end
