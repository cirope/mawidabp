module Users::StatusHelper
  def user_weaknesses_links
    [pending_link, complete_link].join ' | '
  end

  def high_risk_weaknesses_graph_placeholder
    content_tag(
      :div, nil, id: 'high_risk_weaknesses_graph',
      data: {
        graph: true,
        weaknesses: Weakness.weaknesses_for_graph(@weaknesses.with_highest_risk),
        total: @weaknesses.with_highest_risk.count
      }
    )
  end

  def weaknesses_graph_placeholder
    content_tag(
      :div, '', id: 'status_weaknesses_graph',
      data: {
        graph: true,
        weaknesses: Weakness.weaknesses_for_graph(@weaknesses),
        total: @weaknesses.count
      }
    )
  end

  def pending_weaknesses_graph_placeholder
    content_tag(
      :div, '', id: 'pending_weaknesses_graph',
      data: {
        graph: true,
        weaknesses: Weakness.pending_weaknesses_for_graph(@weaknesses),
        total: @weaknesses.with_pending_status.count
      }
    )
  end

  private

    def pending_link
      text = textilize_without_paragraph t('.weaknesses.pending', count: pending_count)
      path = findings_path(completed: 'incomplete', user_id: @user.id)

      link_to_unless pending_count == 0, text, path
    end

    def complete_link
      complete_count = filtered_weaknesses.count - pending_count
      text = textilize_without_paragraph t('.weaknesses.complete', count: complete_count)
      path = findings_path(completed: 'complete', user_id: @user.id)

      link_to_unless complete_count == 0, text, path
    end

    def pending_count
      filtered_weaknesses.with_pending_status.count
    end

    def filtered_weaknesses
      @user.weaknesses.for_current_organization.finals(false).not_incomplete
    end
end
