module WelcomeHelper
  def finding_comment_url finding_answer
    finding = finding_answer.finding
    state   = finding.pending? ? 'incomplete' : 'complete'

    finding_url finding,
                completion_state: state,
                anchor: "comment-#{finding_answer.id}"
  end
end
