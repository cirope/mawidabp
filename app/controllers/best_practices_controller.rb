# =Controlador de buenas prácticas
#
# Lista, muestra, crea, modifica y elimina buenas prácticas (#BestPractice),
# procesos de negocio (#ProcessControl) y objetivos de control
# (#ControlObjective)
class BestPracticesController < ApplicationController
  before_filter :auth, :check_privileges
  hide_action :find_with_organization

  # Lista las buenas prácticas
  #
  # * GET /best_practices
  # * GET /best_practices.xml
  def index
    @title = t :'best_practice.index_title'
    @best_practices = BestPractice.where(
      :organization_id => @auth_organization.id
    ).order('created_at DESC').paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @best_practices }
    end
  end

  # Muestra el detalle de una buena práctica
  #
  # * GET /best_practices/1
  # * GET /best_practices/1.xml
  def show
    @title = t :'best_practice.show_title'
    @best_practice = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @best_practice }
    end
  end

  # Permite ingresar los datos para crear una nueva buena práctica
  #
  # * GET /best_practices/new
  # * GET /best_practices/new.xml
  def new
    @title = t :'best_practice.new_title'
    @best_practice = BestPractice.new
    @best_practice.process_controls.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @best_practice }
    end
  end

  # Recupera los datos para modificar una buena práctica
  #
  # * GET /best_practices/1/edit
  def edit
    @title = t :'best_practice.edit_title'
    @best_practice = find_with_organization(params[:id])
  end

  # Crea una nueva buena práctica siempre que cumpla con las validaciones.
  # Además crea los procesos de negocio y los objetivos de control que la
  # componen.
  #
  # * POST /best_practices
  # * POST /best_practices.xml
  def create
    @title = t :'best_practice.new_title'
    @best_practice = BestPractice.new(params[:best_practice])

    respond_to do |format|
      if @best_practice.save
        flash.notice = t :'best_practice.correctly_created'
        format.html { redirect_to(edit_best_practice_url(@best_practice)) }
        format.xml  { render :xml => @best_practice, :status => :created, :location => @best_practice }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @best_practice.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de una buena práctica siempre que cumpla con las
  # validaciones. Además actualiza el contenido de los procesos de negocio y de
  # los objetivos de control que la componen.
  #
  # * PUT /best_practices/1
  # * PUT /best_practices/1.xml
  def update
    @title = t :'best_practice.edit_title'
    @best_practice = find_with_organization(params[:id])
    params[:best_practice][:organization_id] = @best_practice.organization_id

    respond_to do |format|
      if @best_practice.update_attributes(params[:best_practice])
        flash.notice = t :'best_practice.correctly_updated'
        format.html { redirect_to(edit_best_practice_url(@best_practice)) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @best_practice.errors, :status => :unprocessable_entity }
      end
    end
    
  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'best_practice.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina una buena práctica
  #
  # * DELETE /best_practices/1
  # * DELETE /best_practices/1.xml
  def destroy
    @best_practice = find_with_organization(params[:id])

    unless @best_practice.destroy
      flash.alert = @best_practice.errors.full_messages.join(
        APP_ENUM_SEPARATOR)
    end

    respond_to do |format|
      format.html { redirect_to(best_practices_url) }
      format.xml  { head :ok }
    end
  end
  
  private

  # Busca la buena práctica indicada siempre que pertenezca a la organización.
  # En el caso que no se encuentre (ya sea que no existe una buena práctica con
  # ese ID o que no pertenece a la organización con la que se autenticó el
  # usuario) devuelve nil.
  # _id_::  ID de la buena práctica que se quiere recuperar
  def find_with_organization(id) #:doc:
    BestPractice.where(
      :id => id, :organization_id => @auth_organization.id
    ).first(:readonly => false)
  end
end