class WeaknessTemplatesController < ApplicationController
  include AutoCompleteFor::ControlObjective

  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_weakness_template, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET /weakness_templates
  def index
    build_search_conditions WeaknessTemplate

    @weakness_templates = WeaknessTemplate.list.where(@conditions).order(:title).page params[:page]
  end

  # GET /weakness_templates/1
  def show
  end

  # GET /weakness_templates/new
  def new
    @weakness_template = WeaknessTemplate.list.new
  end

  # GET /weakness_templates/1/edit
  def edit
  end

  # POST /weakness_templates
  def create
    @weakness_template = WeaknessTemplate.list.new weakness_template_params

    @weakness_template.save

    respond_with @weakness_template
  end

  # PATCH/PUT /weakness_templates/1
  def update
    update_resource @weakness_template, weakness_template_params

    respond_with @weakness_template
  end

  # DELETE /weakness_templates/1
  def destroy
    @weakness_template.destroy

    respond_with @weakness_template
  end

  private

    def set_weakness_template
      @weakness_template = WeaknessTemplate.list.find params[:id]
    end

    def weakness_template_params
      params.require(:weakness_template).permit(
        :title, :description, :risk, :lock_version,
        impact: [], operational_risk: [], internal_control_components: [],
        control_objective_weakness_template_relations_attributes: [
          :id, :control_objective_id, :_destroy
        ]
      )
    end

    def load_privileges
      @action_privileges.update auto_complete_for_control_objective: :read
    end
end
