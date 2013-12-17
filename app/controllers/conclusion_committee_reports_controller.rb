class ConclusionCommitteeReportsController < ApplicationController
  include Reports::ControlObjectiveStats
  include Reports::ProcessControlStats
  include Reports::WeaknessesByRiskReport
  include Reports::FixedWeaknessesReport
  include Reports::SynthesisReport
  include Parameters::Risk

  before_action :auth, :load_privileges, :check_privileges

  # Muestra una lista con los reportes disponibles
  #
  # * GET /conclusion_committee_reports
  def index
    @title = t('conclusion_committee_report.index_title')

    respond_to do |format|
      format.html
    end
  end

  private

  def load_privileges #:nodoc:
    @action_privileges.update(
      :synthesis_report => :read,
      :create_synthesis_report => :read,
      :high_risk_weaknesses_report => :read,
      :create_high_risk_weaknesses_report => :read,
      :fixed_weaknesses_report => :read,
      :create_fixed_weaknesses_report => :read,
      :control_objective_stats => :read,
      :create_control_objective_stats => :read,
      :process_control_stats => :read,
      :create_process_control_stats => :read
    )
  end
end
