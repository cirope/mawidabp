class ConclusionReportsController < ApplicationController
  include Reports::SynthesisReport
  include Reports::ReviewStatsReport
  include Reports::ReviewScoresReport
  include Reports::ReviewScoreDetailsReport
  include Reports::WeaknessesByState
  include Reports::WeaknessesByRisk
  include Reports::WeaknessesByAuditType
  include Reports::ControlObjectiveStats
  include Reports::ControlObjectiveStatsByReview
  include Reports::ProcessControlStats
  include Reports::WeaknessesByBusinessUnit
  include Reports::WeaknessesByMonth
  include Reports::WeaknessesByRiskReport
  include Reports::WeaknessesByUser
  include Reports::FixedWeaknessesReport
  include Reports::CostAnalysis
  include Reports::CostSummary
  include Reports::WeaknessesGraph
  include Reports::Benefits

  before_action :auth, :load_privileges, :check_privileges

  # Muestra una lista con los reportes disponibles
  #
  # * GET /conclusion_report
  def index
    @title = t('conclusion_report.index_title')

    respond_to do |format|
      format.html
    end
  end

  private
    def load_privileges #:nodoc:
      @action_privileges.update(
        synthesis_report: :read,
        create_synthesis_report: :read,
        review_stats_report: :read,
        create_review_stats_report: :read,
        review_scores_report: :read,
        create_review_scores_report: :read,
        weaknesses_by_state: :read,
        create_weaknesses_by_state: :read,
        weaknesses_by_risk: :read,
        create_weaknesses_by_risk: :read,
        weaknesses_by_month: :read,
        create_weaknesses_by_month: :read,
        weaknesses_by_risk_report: :read,
        create_weaknesses_by_risk_report: :read,
        weaknesses_by_audit_type: :read,
        create_weaknesses_by_audit_type: :read,
        weaknesses_by_business_unit: :read,
        create_weaknesses_by_business_unit: :read,
        weaknesses_by_user: :read,
        create_weaknesses_by_user: :read,
        cost_analysis: :read,
        cost_summary: :read,
        create_cost_analysis: :read,
        high_risk_weaknesses_report: :read,
        create_high_risk_weaknesses_report: :read,
        fixed_weaknesses_report: :read,
        create_fixed_weaknesses_report: :read,
        control_objective_stats: :read,
        create_control_objective_stats: :read,
        process_control_stats: :read,
        create_process_control_stats: :read,
        benefits: :read,
        create_benefits: :read,
        auto_complete_for_business_unit: :read,
        auto_complete_for_process_control: :read
      )
    end
end
