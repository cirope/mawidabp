# =Controlador de periodos
#
# Lista, muestra, crea, modifica y elimina periodos (#Period)
class PeriodsController < ApplicationController
  before_action :auth, :check_privileges
  before_action :set_period, only: [:show, :edit, :update, :destroy]

  # Lista las periodos
  #
  # * GET /periods
  # * GET /periods.xml
  def index
    @title = t 'period.index_title'
    @periods = Period.list.reorder('start DESC').paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @periods }
    end
  end

  # Muestra el detalle de un periodo
  #
  # * GET /periods/1
  # * GET /periods/1.xml
  def show
    @title = t 'period.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @period }
    end
  end

  # Permite ingresar los datos para crear un nuevo periodo
  #
  # * GET /periods/new
  # * GET /periods/new.xml
  def new
    @title = t 'period.new_title'
    @period = Period.new
    session[:back_to] = params[:back_to]

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @period }
    end
  end

  # Recupera los datos para modificar un periodo
  #
  # * GET /periods/1/edit
  def edit
    @title = t 'period.edit_title'
  end

  # Crea un nuevo periodo siempre que cumpla con las validaciones.
  #
  # * POST /periods
  # * POST /periods.xml
  def create
    @title = t 'period.new_title'
    @period = Period.list.new(period_params)

    respond_to do |format|
      if @period.save
        flash.notice = t 'period.correctly_created'
        back_to, session[:back_to] = session[:back_to], nil
        format.html { redirect_to(back_to || periods_url) }
        format.xml  { render :xml => @period, :status => :created, :location => @period }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @period.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un periodo siempre que cumpla con las
  # validaciones.
  #
  # * PATCH /periods/1
  # * PATCH /periods/1.xml
  def update
    @title = t 'period.edit_title'

    respond_to do |format|
      if @period.update(period_params)
        flash.notice = t 'period.correctly_updated'
        format.html { redirect_to(periods_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @period.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'period.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina un periodo
  #
  # * DELETE /periods/1
  # * DELETE /periods/1.xml
  def destroy
    unless @period.destroy
      flash.alert = ([t('period.errors.can_not_be_destroyed')] +
          @period.errors.full_messages).join(APP_ENUM_SEPARATOR)
    end

    respond_to do |format|
      format.html { redirect_to(periods_url) }
      format.xml  { head :ok }
    end
  end

  private
    def set_period
      @period = Period.find(params[:id])
    end

    def period_params
      params.require(:period).permit(
        :number, :description, :start, :end, :lock_version
      )
    end
end
