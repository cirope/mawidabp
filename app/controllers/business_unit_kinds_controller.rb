class BusinessUnitKindsController < ApplicationController
  respond_to :html, :json

  before_action :auth, :check_privileges
  before_action :set_business_unit_kind, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET /business_unit_kinds
  def index
    @business_unit_kinds = BusinessUnitKind.page(params[:page])
  end

  # GET /business_unit_kinds/1
  def show
  end

  # GET /business_unit_kinds/new
  def new
    @business_unit_kind = BusinessUnitKind.new
  end

  # GET /business_unit_kinds/1/edit
  def edit
  end

  # POST /business_unit_kinds
  def create
    @business_unit_kind = BusinessUnitKind.new(business_unit_kind_params)

    @business_unit_kind.save
    respond_with @business_unit_kind
  end

  # PATCH/PUT /business_unit_kinds/1
  def update
    update_resource @business_unit_kind, business_unit_kind_params
    respond_with @business_unit_kind
  end

  # DELETE /business_unit_kinds/1
  def destroy
    @business_unit_kind.destroy
    respond_with @business_unit_kind
  end

  private

    def set_business_unit_kind
      @business_unit_kind = BusinessUnitKind.find(params[:id])
    end

    def business_unit_kind_params
      params.require(:business_unit_kind).permit :name
    end
end
