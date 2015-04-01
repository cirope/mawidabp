class BenefitsController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_benefit, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET /benefits
  def index
    @benefits = Benefit.list.order(kind: :desc, created_at: :asc).page(params[:page])
  end

  # GET /benefits/1
  def show
  end

  # GET /benefits/new
  def new
    @benefit = current_organization.benefits.new
  end

  # GET /benefits/1/edit
  def edit
  end

  # POST /benefits
  def create
    @benefit = current_organization.benefits.new benefit_params

    @benefit.save
    respond_with @benefit
  end

  # PATCH/PUT /benefits/1
  def update
    update_resource @benefit, benefit_params
    respond_with @benefit
  end

  # DELETE /benefits/1
  def destroy
    @benefit.destroy
    respond_with @benefit
  end

  private

    def set_benefit
      @benefit = Benefit.list.find params[:id]
    end

    def benefit_params
      params.require(:benefit).permit :name, :kind
    end
end
