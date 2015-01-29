class PeriodsController < ApplicationController
  respond_to :html

  before_action :auth, :check_privileges
  before_action :set_period, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: :destroy

  # * GET /periods
  def index
    @periods = Period.list.reorder(start: :desc).page(params[:page])

    respond_with @periods
  end

  # * GET /periods/1
  def show
  end

  # * GET /periods/new
  def new
    @period = Period.new
    session[:back_to] = params[:back_to]
  end

  # * GET /periods/1/edit
  def edit
  end

  # * POST /periods
  def create
    @period = Period.list.new period_params

    respond_to do |format|
      if @period.save
        back_to, session[:back_to] = session[:back_to], nil
        format.html { redirect_to(back_to || periods_url) }
      else
        format.html { render 'new' }
      end
    end
  end

  # * PATCH /periods/1
  def update
    update_resource @period, period_params
    respond_with @period, location: periods_url unless response_body
  end

  # * DELETE /periods/1
  def destroy
    unless @period.destroy
      flash.alert = (
        [t('periods.errors.can_not_be_destroyed')] + @period.errors.full_messages
      ).join(APP_ENUM_SEPARATOR)
    end
    respond_with @period, location: periods_url
  end

  private

    def set_period
      @period = Period.list.find params[:id]
    end

    def period_params
      params.require(:period).permit :number, :description, :start, :end,
        :lock_version
    end
end
