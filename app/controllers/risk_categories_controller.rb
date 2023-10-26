class RiskCategoriesController < ApplicationController
  respond_to :js

  before_action :auth
  before_action :set_risk_registry
  before_action :set_risk_category, only: [:edit]

  def new
    @risk_category = @risk_registry.risk_categories.new
  end

  def edit
  end

  private

    def set_risk_registry
      @risk_registry = RiskRegistry.find params[:risk_registry_id]
    end

    def set_risk_category
      @risk_category = @risk_registry.risk_categories.find params[:id]
    end
end
