module ConclusionAuditReportsHelper
  def audit_by_type_reviews_array(conclusion_reviews)
    conclusion_reviews.map do |cr|
      findings_count = cr.review.final_weaknesses.size +
        cr.review.final_oportunities.size
      text = "<b>#{cr.review}</b>: #{cr.review.score_text}"

      if findings_count == 0
        text << " (#{t(:'conclusion_committee_report.weaknesses_by_audit_type.without_weaknesses')})"
      end

      text
    end
  end
end