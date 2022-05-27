# frozen_string_literal: true

class MemosController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_memo, only: [:show, :edit, :update, :export_to_pdf]
  before_action :set_title, except: [:create, :update]

  # * GET /memos
  def index
    @memos = Memo.list
                 .search(**search_params)
                 .order(id: :asc)
                 .page params[:page]
  end

  # * GET /memos/1
  def show
  end

  # * GET /memos/new
  def new
    @memo = Memo.list.new
  end

  # * POST /memos
  def create
    @memo = Memo.list.new memo_params

    if @memo.save
      flash.notice = t 'memo.correctly_created'
      redirect_to edit_memo_url(@memo)
    else
      render action: :new
    end
  end

  # * GET /memos/1/edit
  def edit
  end

  # * PATCH /memos/1
  def update
    if @memo.update memo_params
      flash.notice = t 'memo.correctly_updated'
      redirect_to edit_memo_url(@memo)
    else
      render action: :edit
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'memo.stale_object_error'
    redirect_to action: :edit
  end

  # * GET /memos/plan_item_refresh?period_id=1
  def plan_item_refresh
    grouped_plan_items = PlanItem.list_unused(params[:period_id])
                                 .group_by(&:business_unit_type)

    @business_unit_types = grouped_plan_items.map do |but, plan_items|
      sorted_plan_items = plan_items.sort_by &:project

      OpenStruct.new name: but.name, plan_items: sorted_plan_items
    end

    respond_to do |format|
      format.js
    end
  end

  # * GET /memos/1/export_to_pdf
  def export_to_pdf
    @memo.to_pdf

    respond_to do |format|
      format.html { redirect_to @memo.relative_pdf_path }
    end
  end

  private

    def set_memo
      @memo = Memo.list.find params[:id]
    end

    def memo_params
      params.require(:memo).permit(
        :period_id, :plan_item_id, :name, :description,
        :required_by, :close_date, :lock_version,
        file_model_memos_attributes: [
          :id, :_destroy,
          file_model_attributes: [:id, :file, :file_cache, :_destroy]
        ]
      )
    end
end
