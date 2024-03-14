class PeriodsController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_period, only: [:show, :edit, :update, :destroy]
  before_action :set_title, except: :destroy

  # * GET /periods
  def index
    @periods = Period.list.reorder(start: :desc).page(params[:page])
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

    if @period.save
      back_to, session[:back_to] = session[:back_to], nil

      redirect_with_notice @period, url: (back_to || periods_url)
    else
      render 'new', status: :unprocessable_entity
    end
  end

  # * PATCH /periods/1
  def update
    if @period.update period_params
      redirect_with_notice @period, url: periods_url
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  # * DELETE /periods/1
  def destroy
    unless @period.destroy
      flash.alert = (
        [t('periods.errors.can_not_be_destroyed')] + @period.errors.full_messages
      ).join(APP_ENUM_SEPARATOR)
    end
    redirect_with_notice @period, url: periods_url
  end

  private

    def set_period
      @period = Period.list.find params[:id]
    end

    def period_params
      params.require(:period).permit :name, :description, :start, :end,
        :lock_version
    end
end
