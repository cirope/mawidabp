class BenefitsController < ApplicationController
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

    if @benefit.save
      redirect_with_notice @benefit
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /benefits/1
  def update
    if @benefit.update benefit_params
      redirect_with_notice @benefit
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # DELETE /benefits/1
  def destroy
    @benefit.destroy
    redirect_with_notice @benefit
  end

  private

    def set_benefit
      @benefit = Benefit.list.find params[:id]
    end

    def benefit_params
      params.require(:benefit).permit :name, :kind
    end
end
