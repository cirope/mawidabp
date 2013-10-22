class FollowUpManagementController < ApplicationController
  include Reports::WeaknessesByState                                                                                                  
  include Reports::WeaknessesByRisk
  include Reports::WeaknessesByAuditType
  include Reports::ControlObjectiveStats
  include Reports::ProcessControlStats

  before_action :auth, :load_privileges, :check_privileges

  # Muestra una lista con los reportes disponibles
  #
  # * GET /follow_up_management
  def index
    @title = t 'follow_up_management.index_title'

    respond_to do |format|
      format.html
    end
  end

  private
    def load_privileges #:nodoc:
      @action_privileges.update(
        :weaknesses_by_state => :read,
        :create_weaknesses_by_state => :read,
        :weaknesses_by_risk => :read,
        :create_weaknesses_by_risk => :read,
        :weaknesses_by_audit_type => :read,
        :create_weaknesses_by_audit_type => :read,
        :control_objective_stats => :read,
        :create_control_objective_stats => :read,
        :process_control_stats => :read,
        :create_process_control_stats => :read
      )
    end
end
