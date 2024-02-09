class RiskAssessmentTemplatesController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_risk_assessment_template, only: [:show, :edit, :update, :destroy]
  before_action :set_clone_from, only: [:new]
  before_action :set_title, except: [:destroy]

  # GET /risk_assessment_templates
  def index
    @risk_assessment_templates = RiskAssessmentTemplate.list.
      search(**search_params).
      order(:name).
      page params[:page]
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

    if @risk_assessment_template.save
      redirect_with_notice @risk_assessment_template
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /risk_assessment_templates/1
  def update
    if @risk_assessment_template.update risk_assessment_template_params
      redirect_with_notice @risk_assessment_template
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # DELETE /risk_assessment_templates/1
  def destroy
    @risk_assessment_template.destroy
    redirect_with_notice @risk_assessment_template
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
      params.require(:risk_assessment_template).permit :name, :description, :formula,
        :lock_version, risk_assessment_weights_attributes: [
          :id, :identifier, :name, :description, :heatmap, :_destroy,
          risk_score_items_attributes: [
            :id, :name, :value, :_destroy
          ]
        ]
    end
end
