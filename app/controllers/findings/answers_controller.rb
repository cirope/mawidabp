class Findings::AnswersController < ApplicationController
  include Findings::SetFinding

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_finding, only: [:create, :update]
  before_action :set_finding_answer, :set_endorsement, only: [:update]

  def create
    @finding_answer = @finding.finding_answers.build finding_answer_params

    if @finding.save
      redirect_with_notice @finding_answer, url: finding_url(params[:completion_state], @finding)
    else
      flash.now[:alert] = t('flash.finding_answers.create.alert')

      render 'findings/show', status: :unprocessable_entity
    end
  end

  def update
    if params[:approve].present?
      @endorsement.update! status: 'approved', reason: params[:reason]
    else
      @endorsement.update! status: 'rejected', reason: params[:reason]
    end
  end

  private

    def finding_answer_params
      params.require(:finding_answer).permit(
        :answer, :user_id, :commitment_date, :notify_users, :skip_commitment_support,
        file_model_attributes: [:file, :file_cache],
        commitment_support_attributes: [:id, :reason, :plan, :controls]
      )
    end

    def set_finding_answer
      @finding_answer = @finding.finding_answers.find params[:id]
    end

    def set_endorsement
      @endorsement = @finding_answer.endorsements.where(user_id: @auth_user.id).take!
    end

    def load_privileges
      @action_privileges.update create: :read, update: :read
    end
end
