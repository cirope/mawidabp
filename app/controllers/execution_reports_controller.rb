class ExecutionReportsController < ApplicationController
  include Reports::WeaknessesByStateExecution
  include Reports::DetailedManagement
  include Reports::WeaknessesReport

  before_action :auth, :load_privileges, :check_privileges

  def index
    @title = t 'execution_reports.index_title'

    respond_to do |format|
      format.html
    end
  end

  private
    def load_privileges
      @action_privileges.update(
        detailed_management_report: :read,
        create_detailed_management_report: :read,
        weaknesses_by_state_execution: :read,
        create_weaknesses_by_state_execution: :read
      )
    end
end
