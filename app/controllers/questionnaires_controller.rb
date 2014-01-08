class QuestionnairesController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_questionnaire, only: [:show, :edit, :update, :destroy]

  # GET /questionnaires
  # GET /questionnaires.json
  def index
    @title = t 'questionnaire.index_title'
    @questionnaires = Questionnaire.list.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @questionnaires }
    end
  end

  # GET /questionnaires/1
  # GET /questionnaires/1.json
  def show
    @title = t 'questionnaire.show_title'

    if @questionnaire.nil?
      redirect_to questionnaires_url, :alert => t('questionnaire.not_found')
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @questionnaire }
    end
  end

  # GET /questionnaires/new
  # GET /questionnaires/new.json
  def new
    @title = t 'questionnaire.new_title'
    @questionnaire = Questionnaire.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @questionnaire }
    end
  end

  # GET /questionnaires/1/edit
  def edit
    @title = t 'questionnaire.edit_title'

    if @questionnaire.nil?
      redirect_to questionnaires_url, :alert => t('questionnaire.not_found')
    end
  end

  # POST /questionnaires
  # POST /questionnaires.json
  def create
    @title = t 'questionnaire.new_title'
    @questionnaire = Questionnaire.list.new(questionnaire_params)

    @questionnaire.questions.each do |question|
      if question.answer_multi_choice?
        Question::ANSWER_OPTIONS.each do |option|
          ao = AnswerOption.new
          ao.option = option
          question.answer_options << ao
        end
      end
    end

    respond_to do |format|
      if @questionnaire.save
        format.html { redirect_to @questionnaire, :notice => t('questionnaire.correctly_created') }
        format.json { render :json => @questionnaire, :status => :created, :location => @questionnaire }
      else
        format.html { render :action => "new" }
        format.json { render :json => @questionnaire.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PATCH /questionnaires/1
  # PATCH /questionnaires/1.json
  def update
    @title = t 'questionnaire.edit_title'

    if @questionnaire.nil?
      redirect_to questionnaires_url, :alert => t('questionnaire.not_found')
    end

    @questionnaire.assign_attributes(questionnaire_params)
    @questionnaire.questions.each do |question|
      if question.answer_multi_choice? && question.answer_options.empty?
        Question::ANSWER_OPTIONS.each do |option|
          ao = AnswerOption.new
          ao.option = option
          question.answer_options << ao
        end
      elsif question.answer_written?
        question.answer_options.clear
      end
    end

    respond_to do |format|
      if @questionnaire.update(questionnaire_params)
        format.html { redirect_to questionnaires_url, :notice => t('questionnaire.correctly_updated') }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @questionnaire.errors, :status => :unprocessable_entity }
      end
    end
  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'questionnaire.stale_object_error'
    redirect_to :action => :edit
  end

  # DELETE /questionnaires/1
  # DELETE /questionnaires/1.json
  def destroy
    @questionnaire.destroy

    respond_to do |format|
      format.html { redirect_to questionnaires_url }
      format.json { head :ok }
    end
  end

  private
    def set_questionnaire
      @questionnaire = Questionnaire.list.find(params[:id])
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
