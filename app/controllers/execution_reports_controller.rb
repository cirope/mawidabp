class ExecutionReportsController < ApplicationController
  include Reports::WeaknessesByStateExecution
  include Reports::WeaknessesReport
  include Reports::PlannedCostSummary
  include Reports::DetailedManagement
  include Reports::ReviewsWithIncompleteWorkPapers

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
        weaknesses_by_state_execution: :read,
        create_weaknesses_by_state_execution: :read,
        weaknesses_report: :read,
        create_weaknesses_report: :read,
        detailed_management_report: :read,
        create_detailed_management_report: :read,
        planned_cost_summary: :read,
        create_planned_cost_summary: :read,
        reviews_with_incomplete_work_papers_report: :read
      )
    end
end
