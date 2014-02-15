module WorkflowsHelper
  def show_detailed_distance_of_time(start_date, end_date)
    distance_text = extended_distance_of_time_in_words(start_date, end_date)
    interval = WorkflowItem.human_attribute_name(:start) + ': ' +
      l(start_date, format: :long) + ', ' +
      WorkflowItem.human_attribute_name(:end) + ': ' +
      l(end_date, format: :long)

    content_tag(:abbr, distance_text, title: interval)
  end

  def review_id_field(f)
    workflow = f.object
    with_period = @workflow.period_id && @workflow.period_id > 0
    collection = (with_period ? Review.list_without_final_review.
              list_all_without_workflow(@workflow.period_id).
              map { |r| [r.identification, r.id] } : [])
    disabled = (with_period && @workflow.new_record?) ? false : true

    f.input :review_id, collection: collection, prompt: true, disabled: disabled
  end
end
