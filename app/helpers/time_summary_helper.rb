module TimeSummaryHelper
  def time_summary_prev_week_path
    time_summary_index_path start_date: @start_date.weeks_ago(1),
                            end_date:   @end_date.weeks_ago(1)
  end

  def time_summary_next_week_path
    time_summary_index_path start_date: @start_date.weeks_since(1),
                            end_date:   @end_date.weeks_since(1)
  end

  def time_summary_current_path period
    time_summary_index_path start_date: @start_date.send("beginning_of_#{period}"),
      end_date:   @end_date.send("end_of_#{period}"),
      format: :csv
  end

  def time_summary_completed? date
    total = Array(@items[date]).sum { |_item, hours| hours }

    total >= @work_hours_per_day
  end

  def show_related_users
    users = time_summary_current_user_related_user_options

    select nil, :user_id, sort_options_array(users),
      { prompt: true },
      { name: :user_id, id: :user_id_select, class: 'form-control' }
  end

  def time_summary_current_user_related_user_options
    related = @self_and_descendants

    related.each_with_object([]) do |user, users|
      options = { user_id: user.id }

      users << [user.full_name_with_function, options.to_json]
    end
  end
end
