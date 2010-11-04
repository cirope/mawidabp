require 'pdf/simpletable'

# =Controlador de programas de trabajo
#
# Lista, muestra, crea, modifica y elimina programas de trabajo (#Workflow) y
# sus ítems (#WorkflowItem)
class WorkflowsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :find_with_organization, :update_auth_user_id, :exists?,
    :load_privileges
  layout proc { |controller| controller.request.xhr? ? false : 'application' }

  # Lista los programas de trabajo
  #
  # * GET /workflows
  # * GET /workflows.xml
  def index
    @title = t :'workflow.index_title'
    @workflows = Workflow.paginate(
      :page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => :period,
      :conditions => {
        "#{Period.table_name}.organization_id" => @auth_organization.id
      },
      :order => [
        "#{Period.table_name}.number DESC",
        "#{Workflow.table_name}.created_at DESC"
      ].join(', ')
    )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @workflows }
    end
  end

  # Muestra el detalle de un programa de trabajo
  #
  # * GET /workflows/1
  # * GET /workflows/1.xml
  def show
    @title = t :'workflow.show_title'
    @workflow = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @workflow }
    end
  end

  # Permite ingresar los datos para crear un programa de trabajo
  #
  # * GET /workflows/new
  # * GET /workflows/new.xml
  def new
    @title = t :'workflow.new_title'
    @workflow = Workflow.new
    clone_id = params[:clone_from].respond_to?(:to_i) ?
      params[:clone_from].to_i : 0
    clone_workflow = find_with_organization(clone_id) if exists?(clone_id)

    if clone_workflow
      clone_workflow.workflow_items.each do |wi|
        attributes = wi.attributes.merge(
          :id => nil,
          :resource_utilizations_attributes =>
            wi.resource_utilizations.map { |ru| ru.attributes.merge :id => nil }
        )

        @workflow.workflow_items.build(attributes)
      end
    else
      @workflow.workflow_items.build
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @workflow }
    end
  end

  # Recupera los datos para modificar un programa de trabajo
  #
  # * GET /workflows/1/edit
  def edit
    @title = t :'workflow.edit_title'
    @workflow = find_with_organization(params[:id])
  end

  # Crea un nuevo programa de trabajo siempre que cumpla con las validaciones.
  # Además crea los ítems que lo componen.
  #
  # * POST /workflows
  # * POST /workflows.xml
  def create
    @title = t :'workflow.new_title'
    @workflow = Workflow.new(params[:workflow])
    @workflow.workflow_items.sort! do |wfi_a, wfi_b|
      wfi_a.order_number.to_i <=> wfi_b.order_number.to_i
    end

    respond_to do |format|
      if @workflow.save
        flash.notice = t :'workflow.correctly_created'
        format.html { redirect_to(workflows_path) }
        format.xml  { render :xml => @workflow, :status => :created, :location => @workflow }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @workflow.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un programa de trabajo (o crea una nueva versión
  # del mismo) siempre que cumpla con las validaciones. Además actualiza el
  # contenido de los ítems que lo componen.
  #
  # * PUT /workflows/1
  # * PUT /workflows/1.xml
  def update
    @title = t :'workflow.edit_title'
    @workflow = find_with_organization(params[:id])
    @workflow.workflow_items.sort! do |wfi_a, wfi_b|
      wfi_a.order_number <=> wfi_b.order_number
    end
    
    respond_to do |format|
      if @workflow.update_attributes(params[:workflow])
        flash.notice = t :'workflow.correctly_updated'
        format.html { redirect_to(workflows_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @workflow.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'workflow.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina un programa de trabajo
  #
  # * DELETE /workflows/1
  # * DELETE /workflows/1.xml
  def destroy
    @workflow = find_with_organization(params[:id])
    @workflow.destroy

    respond_to do |format|
      format.html { redirect_to(workflows_url) }
      format.xml  { head :ok }
    end
  end

  # Exporta el programa de trabajo en formato PDF
  #
  # * GET /workflow_items/export_to_pdf/1
  def export_to_pdf
    @workflow = find_with_organization(params[:id])
    @workflow.to_pdf @auth_organization, !params[:include_details].blank?

    respond_to do |format|
      format.html { redirect_to @workflow.relative_pdf_path }
      format.xml  { head :ok }
    end
  end

  # * POST /workflows/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:user_data][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = ["#{Organization.table_name}.id = :organization_id"]
    parameters = {:organization_id => @auth_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{Resource.table_name}.name) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters["user_data_#{i}".to_sym] = "%#{t.downcase}%"
    end
    find_options = {
      :include => [:organizations, :resource],
      :conditions => [conditions.map {|c| "(#{c})"}.join(' AND '), parameters],
      :order => [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ].join(','),
      :limit => 10
    }

    @users = User.all(find_options)
  end

  # Lista los informes del periodo indicado, devuelve un Hash en JSON
  #
  # * GET /reviews/reviews_for_period/?period=id
  def reviews_for_period
    options = [[t(:'support.select.prompt'), '']]
    reviews = Review.list_without_final_review.list_all_without_workflow(
      params[:period])

    reviews.each { |r| options << [r.identification, r.id] }

    render :json => options.to_json
  end

  # * GET /workflows/resource_data/1
  def resource_data
    resource = Resource.find(params[:id])

    render :json => resource.to_json(:only => :cost_per_unit)
  end

  # * GET /workflows/estimated_amount/1
  def estimated_amount
    review = Review.find(params[:id]) unless params[:id].blank?

    render :partial => 'estimated_amount',
      :locals => {:plan_item => review.try(:plan_item)}
  end

  private

  # Busca el programa de trabajo indicado siempre que pertenezca a la
  # organización. En el caso que no se encuentre (ya sea que no existe un
  # programa de trabajo con ese ID o que no pertenece a la organización con la
  # que se autenticó el usuario) devuelve nil.
  # _id_::  ID del programa de trabajo que se quiere recuperar
  def find_with_organization(id) #:doc:
    Workflow.first(
      :include => :period,
      :conditions => {
        :id => id,
        "#{Period.table_name}.organization_id" => @auth_organization.id
      },
      :readonly => false
    )
  end

  # Indica si existe el programa de trabajo indicado, siempre que pertenezca a
  # la organización. En el caso que no se encuentre (ya sea que no existe un
  # programa de trabajo con ese ID o que no pertenece a la organización con la
  # que se autenticó el usuario) devuelve false.
  # _id_::  ID del programa de trabajo que se quiere recuperar
  def exists?(id) #:doc:
    Workflow.first(
      :include => :period,
      :conditions => {
        :id => id,
        "#{Period.table_name}.organization_id" => @auth_organization.id
      }
    )
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
        :export_to_pdf => :read,
        :auto_complete_for_user => :read,
        :reviews_for_period => :read,
        :resource_data => :read,
        :estimated_amount => :read
      })
  end
end