class Findings::AnswersController < ApplicationController
  include Findings::SetFinding

  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_finding, only: [:create]

  def create
    @finding_answer = @finding.finding_answers.build finding_answer_params

    if @finding.save
      flash.notice = t 'flash.finding_answers.create.notice'

      respond_with @finding_answer, location: finding_url(params[:completion_state], @finding)
    else
      flash.now[:alert] = t('flash.finding_answers.create.alert')

      render 'findings/show'
    end
  end

  private

    def finding_answer_params
      params.require(:finding_answer).permit(
        :answer, :user_id, :commitment_date, :notify_users,
        file_model_attributes: [:file, :file_cache],
        commitment_support_attributes: [:id, :reason, :plan, :controls]
      )
    end

    def load_privileges
      @action_privileges.update create: :read
    end
end
