module Users::StatusHelper
  def user_weaknesses_links
    [pending_link, repeated_link, complete_link].join ' | '
  end

  def self_and_descendants_findings_path
    findings_path(
      completion_state: 'incomplete',
      user_ids:  @user.self_and_descendants.pluck('id')
    )
  end

  private

    def pending_link
      text = markdown_without_paragraph t('.weaknesses.pending', count: pending_count)
      path = findings_path(completion_state: 'incomplete', user_id: @user.id)

      link_to_unless pending_count == 0, text, path
    end

    def complete_link
      complete_count = filtered_weaknesses.count - pending_count - repeated_count
      text = markdown_without_paragraph t('.weaknesses.complete', count: complete_count)
      path = findings_path(completion_state: 'complete', user_id: @user.id)

      link_to_unless complete_count == 0, text, path
    end

    def repeated_link
      text = markdown_without_paragraph t('.weaknesses.repeated', count: repeated_count)
      path = findings_path(completion_state: 'repeated', user_id: @user.id)

      link_to_unless repeated_count == 0, text, path
    end

    def pending_count
      filtered_weaknesses.with_pending_status.count
    end

    def repeated_count
      filtered_weaknesses.with_repeated_status.count
    end

    def filtered_weaknesses
      @user.weaknesses.list.finals(false).not_incomplete
    end
end
