require 'modules/conclusion_reports/conclusion_common_reports'

class ConclusionManagementReportsController < ApplicationController
  include ConclusionCommonReports

  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges, :add_weaknesses_synthesis_table,
    :get_weaknesses_synthesis_table_data, :make_date_range

  # Muestra una lista con los reportes disponibles
  #
  # * GET /conclusion_management_reports
  def index
    @title = t('conclusion_management_report.index_title')

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
      :create_control_objective_stats => :read
    )
  end
end