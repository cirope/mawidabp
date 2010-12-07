# =Controlador de informes
#
# Lista, muestra, crea, modifica y elimina informes (#Review) y sus objetivos
# de control (#ControlObjectiveItem)
class ReviewsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :find_with_organization, :update_auth_user_id, :load_privileges,
    :control_objective_items_for_period, :sort_control_objective_items!
  layout proc { |controller| controller.request.xhr? ? false : 'application' }

  # Lista los informes
  #
  # * GET /reviews
  # * GET /reviews.xml
  def index
    @title = t :'review.index_title'
    default_conditions = {
      "#{Period.table_name}.organization_id" => @auth_organization.id
    }

    build_search_conditions Review, default_conditions

    @reviews = Review.includes(:period, {:plan_item => :business_unit}).where(
      @conditions
    ).order(
      [
        "#{Period.table_name}.start DESC",
        "#{Review.table_name}.created_at DESC"
      ].join(', ')
    ).paginate(:page => params[:page], :per_page => APP_LINES_PER_PAGE)

    respond_to do |format|
      format.html {
        if @reviews.size == 1 && !@query.blank? && !params[:page]
          redirect_to edit_review_path(@reviews.first)
        end
      }
      format.xml  { render :xml => @reviews }
    end
  end

  # Muestra el detalle de un informe
  #
  # * GET /reviews/1
  # * GET /reviews/1.xml
  def show
    @title = t :'review.show_title'
    @review = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @review }
    end
  end

  # Permite ingresar los datos para crear un nuevo informe
  #
  # * GET /reviews/new
  # * GET /reviews/new.xml
  def new
    @title = t :'review.new_title'
    first_period = Period.list.first
    @review = Review.new
    clone_id = params[:clone_from].to_i
    clone_review = find_with_organization(clone_id) if exists?(clone_id)

    @review.clone_from clone_review if clone_review
    @review.period_id = params[:period] ?
      params[:period].to_i : first_period.try(:id)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @review }
    end
  end

  # Recupera los datos para modificar un informe
  #
  # * GET /reviews/1/edit
  def edit
    @title = t :'review.edit_title'
    @review = find_with_organization(params[:id])
  end

  # Crea un nuevo informe siempre que cumpla con las validaciones. Además
  # actualiza el contenido de los objetivos de control que lo componen.
  #
  # * POST /reviews
  # * POST /reviews.xml
  def create
    @title = t :'review.new_title'
    @review = Review.new(params[:review])
    
    respond_to do |format|
      if @review.save
        flash.notice = t :'review.correctly_created'
        format.html { redirect_to(edit_review_path(@review)) }
        format.xml  { render :xml => @review, :status => :created, :location => @review }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @review.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un informe siempre que cumpla con las
  # validaciones. Además actualiza el contenido de los objetivos de control que
  # lo componen.
  #
  # * PUT /reviews/1
  # * PUT /reviews/1.xml
  def update
    @title = t :'review.edit_title'
    @review = find_with_organization(params[:id])

    respond_to do |format|
      if @review.update_attributes(params[:review])
        flash.notice = t :'review.correctly_updated'
        format.html { redirect_to(edit_review_path(@review)) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @review.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t :'review.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina un informe
  #
  # * DELETE /reviews/1
  # * DELETE /reviews/1.xml
  def destroy
    @review = find_with_organization(params[:id])

    unless @review.destroy
      flash.alert = t :'review.errors.can_not_be_destroyed'
    end

    respond_to do |format|
      format.html { redirect_to(reviews_url) }
      format.xml  { head :ok }
    end
  end

  # Lista los informes del periodo indicado
  #
  # * GET /reviews/review_data/1.json
  def review_data
    @review = find_with_organization(params[:id])

    respond_to do |format|
      format.json  { render :json => @review.to_json(:only => [],
          :methods => :score_text,
          :include => {
            :business_unit => {:only => :name},
            :plan_item => {:only => :project}
          })
      }
    end
  end

  # Devuelve los papeles de trabajo del informe
  #
  # * GET /reviews/download_work_papers/1
  def download_work_papers
    review = find_with_organization(params[:id])

    review.zip_all_work_papers @auth_organization

    redirect_to review.relative_work_papers_zip_path
  end

  # Devuelve los datos del ítem del plan
  #
  # * GET /reviews/plan_item_data/1
  def plan_item_data
    business_unit = PlanItem.find_by_id(params[:id]).try(:business_unit)
    name = business_unit.try(:name)
    
    type = business_unit.business_unit_type.name if business_unit
    
    render :json => {
      :business_unit_name => name,
      :business_unit_type => type
    }.to_json
  end

  # Devuelve los datos del procedimiento y prueba de control
  #
  # * GET /reviews/procedure_control_data/1
  def procedure_control_data
    @procedure_control = ProcedureControl.includes(:period).where(
      :id => params[:id],
      "#{Period.table_name}.organization_id" => @auth_organization.id
    ).first(:readonly => true)

    render :template => 'procedure_controls/show'
  end

  # Crea el documento de relevamiento del informe
  #
  # * GET /reviews/survey_pdf/1
  def survey_pdf
    review = find_with_organization(params[:id])

    review.survey_pdf(@auth_organization)

    redirect_to review.relative_survey_pdf_path
  end

  # * POST /reviews/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:user_data][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = ["#{Organization.table_name}.id = :organization_id"]
    parameters = {:organization_id => @auth_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.table_name}.name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.last_name) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.function) LIKE :user_data_#{i}",
        "LOWER(#{User.table_name}.user) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters["user_data_#{i}".to_sym] = "%#{t.downcase}%"
    end

    @users = User.includes(:organizations).where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order(
      [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ].join(',')
    ).limit(10)
  end

  # * POST /reviews/auto_complete_for_procedure_control_subitem
  def auto_complete_for_procedure_control_subitem
    @tokens = params[:procedure_control_subitem_data][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{BestPractice.table_name}.organization_id = :organization_id",
      "#{ProcedureControl.table_name}.period_id = :period_id"
    ]
    parameters = {:organization_id => @auth_organization.id,
      :period_id => params[:period_id]}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{ProcedureControlSubitem.table_name}.control_objective_text) LIKE :procedure_control_subitem_data_#{i}",
        "LOWER(#{ProcessControl.table_name}.name) LIKE :procedure_control_subitem_data_#{i}"
      ].join(' OR ')

      parameters["procedure_control_subitem_data_#{i}".to_sym] = "%#{t.downcase}%"
    end

    @procedure_control_subitems = ProcedureControlSubitem.includes(
      :control_objective => {:process_control => :best_practice},
      :procedure_control_item => :procedure_control
    ).where(
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order(
      [
        "#{ProcessControl.table_name}.name ASC",
        "#{ControlObjective.table_name}.name ASC"
      ].join(',')
    ).limit(10)
  end

  # * GET /reviews/estimated_amount/1
  def estimated_amount
    plan_item = PlanItem.find(params[:id]) unless params[:id].blank?

    render :partial => 'estimated_amount', :locals => {:plan_item => plan_item}
  end

  private

  # Busca el informe indicado siempre que pertenezca a la organización. En el
  # caso que no se encuentre (ya sea que no existe un informe con ese ID o que
  # no pertenece a la organización con la que se autenticó el usuario) devuelve
  # nil.
  #
  # _id_::  ID del informe que se quiere recuperar
  def find_with_organization(id) #:doc:
    Review.includes(:period).where(
      :id => id, "#{Period.table_name}.organization_id" => @auth_organization.id
    ).first(:readonly => false)
  end

  # Indica si existe el informe indicado, siempre que pertenezca a la
  # organización. En el caso que no se encuentre (ya sea que no existe un
  # informe con ese ID o que no pertenece a la organización con la que se
  # autenticó el usuario) devuelve false.
  #
  # _id_::  ID del informe que se quiere recuperar
  def exists?(id) #:doc:
    Review.includes(:period).where(
      :id => id, "#{Period.table_name}.organization_id" => @auth_organization.id
    ).first
  end

  def load_privileges #:nodoc:
    @action_privileges.update(
      :review_data => :read,
      :download_work_papers => :read,
      :plan_item_data => :read,
      :procedure_control_data => :read,
      :survey_pdf => :read,
      :auto_complete_for_user => :read,
      :auto_complete_for_procedure_control_subitem => :read,
      :estimated_amount => :read
    )
  end
end