module TimeSummaryHelper
  def time_summary_prev_week_path
    time_summary_index_path start_date: @start_date.weeks_ago(1),
                            end_date:   @end_date.weeks_ago(1),
                            user_id:    @user.id
  end

  def time_summary_next_week_path
    time_summary_index_path start_date: @start_date.weeks_since(1),
                            end_date:   @end_date.weeks_since(1),
                            user_id:    @user.id
  end

  def time_summary_current_path period
    time_summary_index_path start_date: @start_date.send("beginning_of_#{period}"),
                            end_date:   @end_date.send("end_of_#{period}"),
                            user_id:    @user.id,
                            format:     :csv
  end

  def time_summary_completed? date
    total = Array(@items[date]).sum { |_item, hours| hours }

    total >= @work_hours_per_day
  end

  def show_related_users
    users = time_summary_user_options

    select nil, :user_id, sort_options_array(users),
      { prompt: true },
      { name: :user_id, id: :user_id_select, class: 'form-control',
        data: {
          time_summary_url: time_summary_helper_path
        }
      }
  end

  def time_summary_helper_path
    time_summary_index_path start_date: @start_date,
                            end_date:   @end_date,
                            user_id:    '[USER_ID]'
  end

  def time_summary_user_options
    related = @self_and_descendants

    related.map do |user|
       [user.full_name_with_function, user.id]
    end
  end
end
