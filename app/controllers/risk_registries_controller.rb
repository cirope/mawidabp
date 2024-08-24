class RiskRegistriesController < ApplicationController
  include AutoCompleteFor::ControlObjective

  respond_to :html, :json

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_risk_registry, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET /risk_registries
  def index
    @risk_registries = RiskRegistry.
      list.
      search(**search_params).
      ordered.
      page params[:page]
  end

  # GET /risk_registries/1
  def show
  end

  # GET /risk_registries/new
  def new
    @risk_registry = RiskRegistry.new
  end

  # GET /risk_registries/1/edit
  def edit
  end

  # POST /risk_registries
  def create
    @risk_registry = RiskRegistry.list.new risk_registry_params

    if @risk_registry.save
      respond_with @risk_registry, location: edit_risk_registry_url(@risk_registry)
    else
      render action: :new
    end
  end

  # PATCH/PUT /risk_registries/1
  def update
    update_resource @risk_registry, risk_registry_params

    respond_with @risk_registry
  end

  # DELETE /risk_registries/1
  def destroy
    @risk_registry.destroy

    respond_with @risk_registry, location: risk_registries_url
  end

  private

    def set_risk_registry
      @risk_registry = RiskRegistry.list.find params[:id]
    end

    def risk_registry_params
      params.require(:risk_registry).permit :name, :description, :lock_version,
        risk_categories_attributes: [
          :id, :name, :_destroy,
          risks_attributes: [
            :id, :identifier, :name, :cause, :effect, :likelihood,
            :impact, :user_id, :_destroy, risk_control_objectives_attributes: [
              :id, :control_objective_id, :_destroy
            ]
          ]
        ]
    end

    def load_privileges
      @action_privileges.update(
        auto_complete_for_control_objective: :read
      )
    end
end
