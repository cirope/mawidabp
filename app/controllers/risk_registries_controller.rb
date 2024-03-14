class RiskRegistriesController < ApplicationController
  include AutoCompleteFor::ControlObjective

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
      redirect_with_notice @risk_registry,
        url: edit_risk_registry_url(@risk_registry)
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /risk_registries/1
  def update
    if @risk_registry.update risk_registry_params
      redirect_with_notice @risk_registry
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # DELETE /risk_registries/1
  def destroy
    @risk_registry.destroy
    redirect_with_notice @risk_registry
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
