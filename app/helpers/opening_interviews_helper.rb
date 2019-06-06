module OpeningInterviewsHelper
  def opening_interview_review_field f
    reviews = Review.
      list_all_without_opening_interview.
      list_without_final_review.
      order :identification

    collection = reviews.map { |r| [r.identification, r.id] }

    f.input :review_id, collection: collection, prompt: true, input_html: {
      autofocus: true,
      data: {
        opening_interview_review_url: new_opening_interview_path(format: :js)
      }
    }
  end

  def opening_interview_program
    pcs = @review.grouped_control_objective_items.map do |pc, cois|
      program = []

      cois.sort.each do |coi|
        program << [
          coi.control.design_tests,
          coi.control.compliance_tests,
          coi.control.sustantive_tests
        ].reject(&:blank?).join("\n")
      end

      "#{pc.name}\n\n#{program.reject(&:blank?).join "\n\n"}"
    end

    pcs.join "\n\n"
  end
end
