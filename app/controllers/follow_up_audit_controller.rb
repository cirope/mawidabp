class FollowUpAuditController < ApplicationController
  include Reports::SynthesisReport
  include Reports::ReviewStatsReport
  include Reports::QAIndicators
  include Reports::WeaknessesByState
  include Reports::WeaknessesByRisk
  include Reports::WeaknessesByAuditType
  include Reports::ControlObjectiveStats
  include Reports::ControlObjectiveStatsByReview
  include Reports::ProcessControlStats
  include Reports::WeaknessesByRiskReport
  include Reports::WeaknessesByMonth
  include Reports::WeaknessesCurrentSituation
  include Reports::WeaknessesEvolution
  include Reports::FixedWeaknessesReport
  include Reports::FollowUpCostAnalysis
  include Reports::WeaknessesGraph
  include Reports::WeaknessesReport
  include Reports::Benefits
  include Reports::TaggedFindingsReport

  before_action :auth, :load_privileges, :check_privileges

  def index
    @title = t 'follow_up_audit.index_title'
  end

  private
    def load_privileges
      @action_privileges.update(
        qa_indicators: :read,
        create_qa_indicators: :read,
        synthesis_report: :read,
        create_synthesis_report: :read,
        review_stats_report: :read,
        create_review_stats_report: :read,
        weaknesses_by_state: :read,
        create_weaknesses_by_state: :read,
        weaknesses_by_risk: :read,
        create_weaknesses_by_risk: :read,
        weaknesses_by_risk_report: :read,
        create_weaknesses_by_risk_report: :read,
        weaknesses_by_audit_type: :read,
        create_weaknesses_by_audit_type: :read,
        weaknesses_report: :read,
        create_weaknesses_report: :read,
        weaknesses_current_situation: :read,
        create_weaknesses_current_situation: :read,
        weaknesses_evolution: :read,
        weaknesses_graphs: :read,
        cost_analysis: :read,
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
