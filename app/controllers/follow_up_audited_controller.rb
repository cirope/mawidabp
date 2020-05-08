class FollowUpAuditedController < ApplicationController
  include AuditedReports::WeaknessesByUser

  before_action :auth, :load_privileges, :check_privileges

  def index
    @title = t 'follow_up_audited.index_title'
  end

  private
    def load_privileges
      @action_privileges.update(
        weaknesses_by_user: :read,
        create_weaknesses_by_user: :read
      )
    end
end
