# =Controlador de los items de ayuda
#
# Lista, muestra, crea, modifica y elimina items de ayuda (#HelpItem)
class HelpItemsController < ApplicationController
  before_action :auth, :load_current_module
  before_action :set_help_item, only: [:show, :edit, :update, :destroy]

  # Lista de los items ayuda
  #
  # * GET /help_items
  # * GET /help_items.xml
  def index
    @title = t 'help_item.index_title'
    @help_items = HelpItem.order('name ASC').page(params[:page])

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
    @title = t 'help_item.show_title'

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
    @title = t 'help_item.new_title'
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
    @title = t 'help_item.edit_title'
  end

  # Crea un nuevo item de ayuda siempre que cumpla con las validaciones
  #
  # * POST /help_items
  # * POST /help_items.xml
  def create
    @title = t 'help_item.new_title'
    @help_item = HelpItem.new(help_item_params)

    respond_to do |format|
      if @help_item.save
        flash.notice = t 'help_item.correctly_created'
        format.html { redirect_to(show_content_help_content_url(@help_item)) }
        format.xml  { render :xml => @help_item, :status => :created, :location => @help_item }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @help_item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el item de ayuda siempre que cumpla con las validaciones
  #
  # * PATCH /help_items/1
  # * PATCH /help_items/1.xml
  def update
    @title = t 'help_item.edit_title'

    respond_to do |format|
      if @help_item.update(help_item_params)
        flash.notice = t 'help_item.correctly_updated'
        format.html { redirect_to(show_content_help_content_url(@help_item)) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @help_item.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'help_item.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina el item de ayuda indicado
  #
  # * DELETE /help_items/1
  # * DELETE /help_items/1.xml
  def destroy
    @help_item.destroy

    respond_to do |format|
      format.html { redirect_to(help_items_url) }
      format.xml  { head :ok }
    end
  end

  private
    def set_help_item
      @help_item = HelpItem.find(params[:id])
    end

    def help_item_params
      params.require(:help_item).permit(
        :help_content_id, :name, :description, :order_number, :lock_version,
        children_attributes: [
          :id, :name, :description, :order_number, :_destroy
        ]
      )
    end
end
