# =Controlador de los items de ayuda
#
# Lista, muestra, crea, modifica y elimina items de ayuda (#HelpItem)
class HelpItemsController < ApplicationController
  before_filter :auth, :load_current_module

  # Lista de los items ayuda
  #
  # * GET /help_items
  # * GET /help_items.xml
  def index
    @title = t :'help_item.index_title'
    @help_items = HelpItem.paginate(:page => params[:page],
      :per_page => APP_LINES_PER_PAGE, :order => 'name ASC')

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @help_items }
    end
  end

  # Muestra el detalle del item de ayuda
  #
  # * GET /help_items/1
  # * GET /help_items/1.xml
  def show
    @title = t :'help_item.show_title'
    @help_item = HelpItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @help_item }
    end
  end

  # Permite ingresar los datos para crear un nuevo item de ayuda
  #
  # * GET /help_items/new
  # * GET /help_items/new.xml
  def new
    @title = t :'help_item.new_title'
    @help_item = HelpItem.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @help_item }
    end
  end

  # Recupera los datos para editar un item de ayuda
  #
  # * GET /help_items/1/edit
  def edit
    @title = t :'help_item.edit_title'
    @help_item = HelpItem.find(params[:id])
  end

  # Crea un nuevo item de ayuda siempre que cumpla con las validaciones
  #
  # * POST /help_items
  # * POST /help_items.xml
  def create
    @title = t :'help_item.new_title'
    @help_item = HelpItem.new(params[:help_item])

    respond_to do |format|
      if @help_item.save
        flash.notice = t :'help_item.correctly_created'
        format.html { redirect_to(show_content_help_content_path(@help_item)) }
        format.xml  { render :xml => @help_item, :status => :created, :location => @help_item }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @help_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el item de ayuda siempre que cumpla con las validaciones
  #
  # * PUT /help_items/1
  # * PUT /help_items/1.xml
  def update
    @title = t :'help_item.edit_title'
    @help_item = HelpItem.find(params[:id])

    respond_to do |format|
      if @help_item.update_attributes(params[:help_item])
        flash.notice = t :'help_item.correctly_updated'
        format.html { redirect_to(show_content_help_content_path(@help_item)) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @help_item.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'help_item.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina el item de ayuda indicado
  #
  # * DELETE /help_items/1
  # * DELETE /help_items/1.xml
  def destroy
    @help_item = HelpItem.find(params[:id])
    @help_item.destroy

    respond_to do |format|
      format.html { redirect_to(help_items_url) }
      format.xml  { head :ok }
    end
  end
end