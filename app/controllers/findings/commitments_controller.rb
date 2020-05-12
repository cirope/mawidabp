class Findings::CommitmentsController < ApplicationController
  include Findings::CurrentUserScopes
  include Findings::SetFinding

  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_finding, only: [:show]

  def show
    @index           = params[:index].to_i
    @commitment_date = Timeliness.parse params[:id], :date
    @limit_date      = ""

    if defined? ENABLE_LIMIT_COMMITMENT_DATE && ENABLE_LIMIT_COMMITMENT_DATE['limit_date'] == 'true'
      if @finding.follow_up_date
        if params[:id].to_date > @finding.follow_up_date + 12.months && @finding.risk == RISK_TYPES[:high]
          @limit_date = ENABLE_LIMIT_COMMITMENT_DATE["message_one_year"]
        end
      end
    end
  end
end
