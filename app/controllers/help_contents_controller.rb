# =Controlador del contenido de la ayuda
#
# Lista, muestra, crea, modifica y elimina contenido de la ayuda (#HelpContent)
class HelpContentsController < ApplicationController
  before_action :auth, :load_current_module
  before_action :set_help_content, only: [:show, :edit, :update, :destroy]

  # Lista de los contenidos de ayuda
  #
  # * GET /help_contents
  # * GET /help_contents.xml
  def index
    @title = t 'help_content.index_title'
    @help_contents = HelpContent.order('language ASC').paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @help_contents }
    end
  end

  # Muestra el detalle del contenido de ayuda
  #
  # * GET /help_contents/1
  # * GET /help_contents/1.xml
  def show
    @title = t 'help_content.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @help_content }
    end
  end

  # Permite ingresar los datos para crear una nueva ayuda
  #
  # * GET /help_contents/new
  # * GET /help_contents/new.xml
  def new
    @title = t 'help_content.new_title'
    @help_content = HelpContent.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @help_content }
    end
  end

  # Recupera los datos para editar un contenido de ayuda
  # 
  # * GET /help_contents/1/edit
  def edit
    @title = t 'help_content.edit_title'
  end

  # Crea un nuevo contenido de ayuda siempre que cumpla con las validaciones
  #
  # * POST /help_contents
  # * POST /help_contents.xml
  def create
    @title = t 'help_content.new_title'
    @help_content = HelpContent.new(help_content_params)

    respond_to do |format|
      if @help_content.save
        flash.notice = t 'help_content.correctly_created'
        help_item = @help_content.help_items.first
        format.html { redirect_to(help_item ?
              show_content_help_content_url(help_item) : help_contents_url) }
        format.xml  { render :xml => @help_content, :status => :created, :location => @help_content }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @help_content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de ayuda siempre que cumpla con las validaciones
  #
  # * PATCH /help_contents/1
  # * PATCH /help_contents/1.xml
  def update
    @title = t 'help_content.edit_title'

    respond_to do |format|
      if @help_content.update(help_content_params)
        flash.notice = t 'help_content.correctly_updated'
        help_item = @help_content.help_items.first
        format.html { redirect_to(help_item ?
              show_content_help_content_url(help_item) : help_contents_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @help_content.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'help_content.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina el contenido de ayuda indicado
  #
  # * DELETE /help_contents/1
  # * DELETE /help_contents/1.xml
  def destroy
    @help_content.destroy

    respond_to do |format|
      format.html { redirect_to(help_contents_url) }
      format.xml  { head :ok }
    end
  end

  # * GET /help_contents/show_content/1
  def show_content
    @title = t 'help_content.help_title'
    @help_item = params[:id] && HelpItem.exists?(params[:id]) ?
      HelpItem.find(params[:id]) :
      HelpContent.find_by(language: I18n.locale.to_s).try(:help_items).try(:first)
  end

  private
    def set_help_content
      @help_content = HelpContent.find(params[:id])
    end

    def help_content_params
      params.require(:help_content).permit(
        :language, help_items_attributes: [
          :id, :name, :description, :order_number, :_destroy
        ]
      )
    end
end
