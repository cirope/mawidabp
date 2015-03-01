class ConclusionReportsController < ApplicationController
  include Reports::SynthesisReport
  include Reports::WeaknessesByState
  include Reports::WeaknessesByRisk
  include Reports::WeaknessesByAuditType
  include Reports::ControlObjectiveStats
  include Reports::ProcessControlStats
  include Reports::WeaknessesByRiskReport
  include Reports::FixedWeaknessesReport
  include Reports::NonconformitiesReport
  include Reports::CostAnalysis

  before_action :auth, :load_privileges, :check_privileges

  # Muestra una lista con los reportes disponibles
  #
  # * GET /conclusion_report
  def index
    @title = t('conclusion_report.index_title')
    @quality_management = current_organization.kind.eql? 'quality_management'

    respond_to do |format|
      format.html
    end
  end

  private
    def load_privileges #:nodoc:
      @action_privileges.update(
        synthesis_report: :read,
        create_synthesis_report: :read,
        weaknesses_by_state: :read,
        create_weaknesses_by_state: :read,
        weaknesses_by_risk: :read,
        create_weaknesses_by_risk: :read,
        weaknesses_by_audit_type: :read,
        create_weaknesses_by_audit_type: :read,
        cost_analysis: :read,
        create_cost_analysis: :read,
        high_risk_weaknesses_report: :read,
        create_high_risk_weaknesses_report: :read,
        fixed_weaknesses_report: :read,
        create_fixed_weaknesses_report: :read,
        control_objective_stats: :read,
        create_control_objective_stats: :read,
        process_control_stats: :read,
        create_process_control_stats: :read
      )
    end
end
