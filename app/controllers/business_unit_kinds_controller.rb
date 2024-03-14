class BusinessUnitKindsController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_business_unit_kind, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: [:destroy]

  # GET /business_unit_kinds
  def index
    @business_unit_kinds = BusinessUnitKind.list.page params[:page]
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
    @business_unit_kind = BusinessUnitKind.list.new business_unit_kind_params

    if @business_unit_kind.save
      redirect_with_notice @business_unit_kind
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # PATCH/PUT /business_unit_kinds/1
  def update
    if @business_unit_kind.update business_unit_kind_params
      redirect_with_notice @business_unit_kind
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # DELETE /business_unit_kinds/1
  def destroy
    @business_unit_kind.destroy
    redirect_with_notice @business_unit_kind
  end

  private

    def set_business_unit_kind
      @business_unit_kind = BusinessUnitKind.list.find params[:id]
    end

    def business_unit_kind_params
      params.require(:business_unit_kind).permit :name
    end
end
