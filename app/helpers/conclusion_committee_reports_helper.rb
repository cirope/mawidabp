module ConclusionCommitteeReportsHelper
  def synthesis_report_score_average(title, scores)
    unless scores.blank?
      "<strong>#{title}</strong>: <em>#{(scores.sum.to_f / scores.size).round}%</em>"
    else
      t(:'conclusion_committee_report.synthesis_report.without_audits_in_the_period')
    end
  end

  def synthesis_report_organization_score_average(audits_by_business_unit)
    unless audits_by_business_unit.blank?
      count = 0
      total = audits_by_business_unit.inject(0) do |sum, data|
        scores = data[:review_scores]

        if scores.blank?
          sum
        else
          count += 1
          sum + (scores.sum.to_f / scores.size).round
        end
      end

      average_score = count > 0 ? (total.to_f / count).round : 100
    end

    t(:'conclusion_committee_report.synthesis_report.organization_score',
      :score => average_score || 100)
  end
end
