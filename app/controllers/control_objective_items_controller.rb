# =Controlador de objetivos de control
#
# Lista, muestra, modifica y elimina objetivos de control
# (#ControlObjectiveItem)
class ControlObjectiveItemsController < ApplicationController
  before_filter :auth, :check_privileges
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }
  hide_action :find_with_organization

  # Lista los objetivos de control
  #
  # * GET /control_objective_items
  # * GET /control_objective_items.xml
  def index
    @title = t :'control_objective_item.index_title'
    default_conditions = {
      Period.table_name => {:organization_id => @auth_organization.id}
    }

    build_search_conditions ControlObjectiveItem, default_conditions

    @control_objectives = ControlObjectiveItem.paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE,
      :include => [
        {:review => :period},
        {:control_objective => :process_control},
        :weaknesses
      ],
      :conditions => @conditions,
      :order => [
        "#{Review.table_name}.period_id DESC",
        "#{Review.table_name}.identification ASC",
        "#{ControlObjectiveItem.table_name}.created_at DESC"
      ].join(', ')
    )

    respond_to do |format|
      format.html {
        if @control_objectives.size == 1 && !@query.blank? && !params[:page]
          redirect_to edit_control_objective_item_path(@control_objectives.first)
        end
      } # index.html.erb
      format.xml  { render :xml => @control_objective_items }
    end
  end

  # Muestra el detalle de un objetivo de control
  #
  # * GET /control_objective_items/1
  # * GET /control_objective_items/1.xml
  def show
    @title = t :'control_objective_item.show_title'
    @control_objective_item = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @control_objective_item }
    end
  end

  # Recupera los datos para modificar un objetivo de control
  #
  # * GET /control_objective_items/1/edit
  def edit
    @title = t :'control_objective_item.edit_title'
    if params[:control_objective] && params[:review]
      @control_objective_item = ControlObjectiveItem.first(
        :include => :review,
        :conditions => {
          :control_objective_id => params[:control_objective],
          :review_id => params[:review],
          Review.table_name => {:organization_id => @auth_organization.id}
        },
        :order => 'created_at DESC')
      session[:back_to] = edit_review_path(params[:review].to_i)
    else
      @control_objective_item = find_with_organization(params[:id])
    end
  end

  # Actualiza el contenido de un objetivo de control siempre que cumpla con las
  # validaciones.
  #
  # * PUT /control_objective_items/1
  # * PUT /control_objective_items/1.xml
  def update
    @title = t :'control_objective_item.edit_title'
    @control_objective_item = find_with_organization(params[:id])

    respond_to do |format|
      if @control_objective_item.update_attributes(
          params[:control_objective_item])
        flash.notice = t :'control_objective_item.correctly_updated'
        back_to, session[:back_to] = session[:back_to], nil
        format.html { redirect_to(back_to || edit_control_objective_item_path(
              @control_objective_item)) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @control_objective_item.errors, :status => :unprocessable_entity }
      end
    end

    rescue ActiveRecord::StaleObjectError
      flash.alert = t :'control_objective_item.stale_object_error'
      redirect_to :action => :edit
  end

  # Elimina un objetivo de control
  #
  # * DELETE /control_objective_items/1
  # * DELETE /control_objective_items/1.xml
  def destroy
    @control_objective_item = find_with_organization(params[:id])
    @control_objective_item.destroy

    respond_to do |format|
      format.html {
        redirect_to(control_objective_items_url(params.slice(:period, :review)))
      }
      format.xml  { head :ok }
    end
  end

  private

  # Busca el objetivo de control indicado siempre que pertenezca a la
  # organización. En el caso que no se encuentre (ya sea que no existe un
  # objetivo de control con ese ID o que no pertenece a la organización con la
  # que se autenticó el usuario) devuelve nil.
  # _id_::  ID del objetivo de control que se quiere recuperar
  def find_with_organization(id) #:doc:
    ControlObjectiveItem.first(
      :include => {:review => :period},
      :conditions => {
        :id => id,
        Period.table_name => {:organization_id => @auth_organization.id}
      },
      :readonly => false
    )
  end
end