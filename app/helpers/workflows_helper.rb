module WorkflowsHelper
  def show_detailed_distance_of_time(start_date, end_date)
    distance_text = extended_distance_of_time_in_words(start_date, end_date)
    interval = WorkflowItem.human_attribute_name('start') + ": " +
      l(start_date, :format => :long) + ", " +
      WorkflowItem.human_attribute_name('end') + ": " +
      l(end_date, :format => :long)

    content_tag(:abbr, distance_text, :title => interval)
  end
end