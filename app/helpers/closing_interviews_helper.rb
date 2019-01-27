module ClosingInterviewsHelper
  def closing_interview_review_field f
    reviews    = Review.list_all_without_closing_interview.order :identification
    collection = reviews.map { |r| [r.identification, r.id] }

    f.input :review_id, collection: collection, prompt: true, input_html: {
      autofocus: true,
      data: {
        closing_interview_review_url: new_closing_interview_path(format: :js)
      }
    }
  end

  def closing_interview_findings_summary
    closing_interview_weaknesses.map do |w|
      "- #{w.review_code} - #{w.title}"
    end.join "\n"
  end

  def closing_interview_recommendations_summary
    closing_interview_weaknesses.map do |w|
      w.audit_recommendations.presence
    end.compact.join "\n\n"
  end

  def closing_interview_suggestions
    closing_interview_weaknesses.map do |w|
      w.answer.presence
    end.compact.join "\n\n"
  end

  private

    def closing_interview_weaknesses
      weaknesses = []

      @review.grouped_control_objective_items.each do |process_control, cois|
        cois.sort.each do |coi|
          coi.weaknesses.not_revoked.sort_for_review.each do |f|
            weaknesses << f
          end
        end
      end

      weaknesses
    end
end
