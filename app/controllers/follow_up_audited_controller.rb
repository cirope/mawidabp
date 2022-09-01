class FollowUpAuditedController < ApplicationController
  include AuditedReports::WeaknessesByUser
  include AuditedReports::ProcessControlStats

  before_action :auth, :load_privileges, :check_privileges

  def index
    @title = t 'follow_up_audited.index_title'
  end

  private
    def load_privileges
      @action_privileges.update(
        weaknesses_by_user: :read,
        create_weaknesses_by_user: :read,
        process_control_stats: :read,
        create_process_control_stats: :read
      )
    end
end
