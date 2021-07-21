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
    time_summary_remaining_hours(date) <= 0
  end

  def time_summary_remaining_hours date
    total = Array(@items[date]).sum { |_item, hours| hours }

    @work_hours_per_day - total
  end

  def time_summary_user_select
    users = time_summary_user_options

    select nil, :user_id, sort_options_array(users),
      { prompt: false },
      {
        name:  :user_id,
        class: 'form-control',
        data:  {
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
    @self_and_descendants.map do |user|
      [user.full_name_with_function, user.id, selected: user == @user]
    end
  end

  def time_summary_url time_summary
    time_summary.new_record? ? time_summary_index_path : time_summary_path(time_summary)
  end

  def time_summary_enabled_edit item, date
    date >= 1.week.ago
  end

  def time_summary_reviews
    Review.list_without_final_review_or_not_closed.
      map { |r| [r.identification, r.id] }
  end

  def time_summary_activities
    ActivityGroup.list.order(:name).map do |ag|
      children = ag.activities.order(:name).map do |a|
        [a.name, a.id, { data: { require_detail: a.require_detail }}]
      end

      [ag.name, children]
    end
  end

  def time_summary_require_detail_class
    'd-none' unless @time_consumption.require_detail?
  end
end
