require 'modules/follow_up_common_reports'

class FollowUpManagementController < ApplicationController
  include FollowUpCommonReports

  before_filter :auth, :load_privileges, :check_privileges
  hide_action :load_privileges, :get_organization,
    :add_weaknesses_synthesis_table, :being_implemented_resume_from_counts,
    :add_being_implemented_resume, :make_date_range,
    :get_weaknesses_synthesis_table_data

  # Muestra una lista con los reportes disponibles
  #
  # * GET /follow_up_management
  def index
    @title = t :'follow_up_management.index_title'

    respond_to do |format|
      format.html
    end
  end

  private

  def load_privileges #:nodoc:
    @action_privileges.update({
        :weaknesses_by_state => :read,
        :create_weaknesses_by_state => :read,
        :weaknesses_by_risk => :read,
        :create_weaknesses_by_risk => :read,
        :weaknesses_by_audit_type => :read,
        :create_weaknesses_by_audit_type => :read
      })
  end
end