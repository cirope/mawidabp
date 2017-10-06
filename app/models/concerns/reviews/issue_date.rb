module Reviews::IssueDate
  extend ActiveSupport::Concern

  def issue_date include_draft: false
    result   = conclusion_final_review&.issue_date
    result ||= conclusion_draft_review&.issue_date if include_draft

    result || plan_item.start
  end
end
