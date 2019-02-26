class RiskAssessmentTemplatesController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_risk_assessment_template, only: [:show, :edit, :update, :destroy]
  before_action :set_clone_from, only: [:new]
  before_action :set_title, except: [:destroy]

  # GET /risk_assessment_templates
  def index
    build_search_conditions RiskAssessmentTemplate

    @risk_assessment_templates = RiskAssessmentTemplate.list.where(@conditions).order(:name).page params[:page]
  end

  # GET /risk_assessment_templates/1
  def show
  end

  # GET /risk_assessment_templates/new
  def new
    @risk_assessment_template = RiskAssessmentTemplate.list.new

    @risk_assessment_template.clone_from @clone_from if @clone_from
  end

  # GET /risk_assessment_templates/1/edit
  def edit
  end

  # POST /risk_assessment_templates
  def create
    @risk_assessment_template = RiskAssessmentTemplate.list.new risk_assessment_template_params

    @risk_assessment_template.save
    respond_with @risk_assessment_template
  end

  # PATCH/PUT /risk_assessment_templates/1
  def update
    update_resource @risk_assessment_template, risk_assessment_template_params
    respond_with @risk_assessment_template
  end

  # DELETE /risk_assessment_templates/1
  def destroy
    @risk_assessment_template.destroy
    respond_with @risk_assessment_template
  end

  private

    def set_risk_assessment_template
      @risk_assessment_template = RiskAssessmentTemplate.list.find params[:id]
    end

    def set_clone_from
      if params[:clone_from]
        @clone_from = RiskAssessmentTemplate.list.find params[:clone_from]
      end
    end

    def risk_assessment_template_params
      params.require(:risk_assessment_template).permit :name, :description,
        :lock_version, risk_assessment_weights_attributes: [
          :id, :name, :description, :weight, :_destroy
        ]
    end
end
