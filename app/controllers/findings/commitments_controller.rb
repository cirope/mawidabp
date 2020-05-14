class Findings::CommitmentsController < ApplicationController
  include Findings::CurrentUserScopes
  include Findings::SetFinding

  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_finding, only: [:show]

  def show
    @index                = params[:index].to_i
    @commitment_date      = Timeliness.parse params[:id], :date
    @date_warning_message = Finding.commitment_date_message_for @commitment_date, @finding
  end
end
