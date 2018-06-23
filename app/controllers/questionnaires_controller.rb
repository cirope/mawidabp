class QuestionnairesController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_questionnaire, only: [:show, :edit, :update, :destroy]
  before_action :set_title

  # GET /questionnaires
  # GET /questionnaires.json
  def index
    @questionnaires = Questionnaire.list.page params[:page]
  end

  # GET /questionnaires/1
  # GET /questionnaires/1.json
  def show
  end

  # GET /questionnaires/new
  # GET /questionnaires/new.json
  def new
    @questionnaire = Questionnaire.new

    if params[:clone_from].present?
      questionnaire = Questionnaire.list.find_by id: params[:clone_from]

      @questionnaire.clone_from questionnaire
    end
  end

  # GET /questionnaires/1/edit
  def edit
  end

  # POST /questionnaires
  # POST /questionnaires.json
  def create
    @questionnaire = Questionnaire.list.new questionnaire_params

    @questionnaire.save
    respond_with @questionnaire
  end

  # PATCH /questionnaires/1
  # PATCH /questionnaires/1.json
  def update
    update_resource @questionnaire, questionnaire_params
    respond_with @questionnaire unless response_body
  end

  # DELETE /questionnaires/1
  # DELETE /questionnaires/1.json
  def destroy
    @questionnaire.destroy
    respond_with @questionnaire
  end

  private

    def set_questionnaire
      @questionnaire = Questionnaire.list.find params[:id]
    end

    def questionnaire_params
      params.require(:questionnaire).permit(
        :name, :lock_version, :pollable_type, :email_text, :email_subject, :email_link,
        :email_clarification, questions_attributes: [
          :id, :question, :sort_order, :answer_type, :lock_version, :_destroy
        ]
      )
    end
end
