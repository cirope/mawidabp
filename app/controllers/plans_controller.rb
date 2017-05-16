class PlansController < ApplicationController
  include AutoCompleteFor::BusinessUnit
  include AutoCompleteFor::Tagging

  respond_to :html, :js

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_business_unit_type, only: [:show, :new, :edit]
  before_action :set_plan, only: [:show, :edit, :update, :destroy, :export_to_pdf]
  before_action :set_plan_clone, only: [:new, :create]
  before_action :set_title, except: [:destroy]

  # * GET /plans
  def index
    @plans = Plan.list.includes(:period).references(:period).order(
      "#{Period.quoted_table_name}.#{Period.qcn('start')} DESC"
    ).page params[:page]
  end

  # * GET /plans/1
  def show
    respond_to do |format|
      format.html
      format.js
      format.pdf  { redirect_to plan_pdf_path }
    end
  end

  # * GET /plans/new
  def new
    @plan = Plan.new

    @plan.clone_from @plan_clone if @plan_clone
  end

  # * GET /plans/1/edit
  def edit
  end

  # * POST /plans
  def create
    @plan = Plan.list.new plan_params

    @plan.clone_from @plan_clone if @plan_clone

    @plan.save

    respond_with @plan, location: -> {
      if @plan.persisted?
        edit_plan_url @plan, business_unit_type: params[:business_unit_type]
      end
    }
  end

  # * PATCH /plans/1
  def update
    update_resource @plan, plan_params

    respond_with @plan, location: edit_plan_url(@plan, business_unit_type: params[:business_unit_type])
  end

  # * DELETE /plans/1
  def destroy
    @plan.destroy

    respond_with @plan, location: plans_url
  end

  private

    def plan_params
      params.require(:plan).permit(
        :period_id, :allow_overload, :allow_duplication,
        :lock_version, plan_items_attributes: [
          :id, :project, :start, :end, :order_number, :business_unit_id,
          :_destroy,
          resource_utilizations_attributes: [
            :id, :resource_id, :resource_type, :units, :_destroy
          ],
          taggings_attributes: [
            :id, :tag_id, :_destroy
          ]
        ]
      )
    end

    def set_business_unit_type
      if params[:business_unit_type].to_i > 0
        @business_unit_type = BusinessUnitType.find params[:business_unit_type]
      end
    end

    def set_plan
      @plan = Plan.list.includes(
        plan_items: [
          :resource_utilizations, :business_unit,
          { review: :conclusion_final_review }
        ]
      ).find(params[:id])
    end

    def set_plan_clone
      @plan_clone = Plan.list.find_by id: params[:clone_from]
    end

    def plan_pdf_path
      @plan.to_pdf current_organization, params[:include_details].present?

      @plan.relative_pdf_path
    end

    def load_privileges
      @action_privileges.update(
        export_to_pdf: :read,
        auto_complete_for_business_unit: :read,
        auto_complete_for_tagging: :read
      )
    end
end
