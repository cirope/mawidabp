class FollowUpAuditController < ApplicationController
  include Reports::SynthesisReport
  include Reports::ReviewStatsReport
  include Reports::QaIndicators
  include Reports::WeaknessesByState
  include Reports::WeaknessesByRisk
  include Reports::WeaknessesByRiskAndBusinessUnit
  include Reports::WeaknessesByAuditType
  include Reports::ControlObjectiveStats
  include Reports::ControlObjectiveStatsByReview
  include Reports::ProcessControlStats
  include Reports::WeaknessesByBusinessUnit
  include Reports::WeaknessesByMonth
  include Reports::WeaknessesByRiskReport
  include Reports::WeaknessesByUser
  include Reports::WeaknessesByControlObjectiveProcess
  include Reports::WeaknessesCurrentSituation
  include Reports::WeaknessesByControlObjective
  include Reports::WeaknessesEvolution
  include Reports::WeaknessesList
  include Reports::WeaknessesBrief
  include Reports::WeaknessesRepeated
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
        weaknesses_by_risk_and_business_unit: :read,
        create_weaknesses_by_risk_and_business_unit: :read,
        weaknesses_by_month: :read,
        create_weaknesses_by_month: :read,
        weaknesses_by_risk_report: :read,
        create_weaknesses_by_risk_report: :read,
        weaknesses_by_audit_type: :read,
        create_weaknesses_by_audit_type: :read,
        weaknesses_report: :read,
        create_weaknesses_report: :read,
        weaknesses_by_business_unit: :read,
        create_weaknesses_by_business_unit: :read,
        weaknesses_by_user: :read,
        create_weaknesses_by_user: :read,
        weaknesses_current_situation: :read,
        create_weaknesses_current_situation: :read,
        create_weaknesses_current_situation_permalink: :read,
        weaknesses_by_control_objective: :read,
        create_weaknesses_by_control_objective: :read,
        weaknesses_evolution: :read,
        create_weaknesses_evolution: :read,
        weaknesses_list: :read,
        weaknesses_brief: :read,
        weaknesses_graphs: :read,
        weaknesses_repeated: :read,
        create_weaknesses_repeated: :read,
        cost_analysis: :read,
        create_cost_analysis: :read,
        high_risk_weaknesses_report: :read,
        create_high_risk_weaknesses_report: :read,
        fixed_weaknesses_report: :read,
        create_fixed_weaknesses_report: :read,
        control_objective_stats: :read,
        create_control_objective_stats: :read,
        control_objective_stats_by_review: :read,
        create_control_objective_stats_by_review: :read,
        process_control_stats: :read,
        create_process_control_stats: :read,
        benefits: :read,
        create_benefits: :read,
        auto_complete_for_business_unit: :read,
        auto_complete_for_process_control: :read,
        weaknesses_by_control_objective_process: :read,
        create_weaknesses_by_control_objective_process: :read
      )
    end
end
