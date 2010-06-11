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

    @reviews = Review.paginate(:page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => [:period, {:plan_item => :business_unit}],
      :order => [
        "#{Period.table_name}.start DESC",
        "#{Review.table_name}.created_at DESC"
      ].join(', '),
      :conditions => @conditions
    )

    respond_to do |format|
      format.html {
        if @reviews.size == 1 && !@query.blank?
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
    @review = Review.new(
      :period_id => params[:period] ?
        params[:period].to_i : (first_period ? first_period.id : nil)
    )
    prepare_review

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
    prepare_review
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
        flash[:notice] = t :'review.correctly_created'
        format.html { redirect_to(edit_review_path(@review)) }
        format.xml  { render :xml => @review, :status => :created, :location => @review }
      else
        prepare_review
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
        flash[:notice] = t :'review.correctly_updated'
        format.html { redirect_to(edit_review_path(@review)) }
        format.xml  { head :ok }
      else
        prepare_review
        format.html { render :action => :edit }
        format.xml  { render :xml => @review.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash[:notice] = t :'review.stale_object_error'
    redirect_to :action => :edit
  end

  # Marca como eliminado un informe
  #
  # * DELETE /reviews/1
  # * DELETE /reviews/1.xml
  def destroy
    @review = find_with_organization(params[:id])

    unless @review.destroy
      flash[:notice] = t :'review.errors.can_not_be_destroyed'
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
    plan_item = PlanItem.first(:conditions => {:id => params[:id]})
    business_unit = plan_item.try(:business_unit)
    name = business_unit.try(:name)
    
    if business_unit
      type = t("organization.business_unit_#{business_unit.type}.type")
    end

    render :json => {
      :business_unit_name => name,
      :business_unit_type => type
    }.to_json
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
    find_options = {
      :include => :organizations,
      :conditions => [conditions.map {|c| "(#{c})"}.join(' AND '), parameters],
      :order => [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ].join(','),
      :limit => 10
    }

    @users = User.all(find_options)
  end

  # * GET /reviews/estimated_amount/1
  def estimated_amount
    plan_item = PlanItem.find(params[:id]) unless params[:id].blank?

    render :partial => 'estimated_amount', :locals => {:plan_item => plan_item}
  end

  private

  def prepare_review
    @review.control_objective_items.each { |coi| coi.included_in_review = true }

    unless @review.has_final_review?
      associated_cois = @review.control_objective_items.map do |coi|
        coi.control_objective_id
      end

      control_objective_items = control_objective_items_for_period(
        @review.period_id, associated_cois.compact)

      coi_attributes = control_objective_items.map do |coi|
        coi.attributes unless coi.included_in_review
      end

      @review.control_objective_items.build(coi_attributes.compact)
    end
    
    sort_control_objective_items! @review.control_objective_items
  end

  # Busca el informe indicado siempre que pertenezca a la organización. En el
  # caso que no se encuentre (ya sea que no existe un informe con ese ID o que
  # no pertenece a la organización con la que se autenticó el usuario) devuelve
  # nil.
  # _id_::  ID del informe que se quiere recuperar
  def find_with_organization(id) #:doc:
    Review.first(
      :include => :period,
      :conditions => {
        :id => id,
        "#{Period.table_name}.organization_id" => @auth_organization.id
      },
      :readonly => false
    )
  end

  # Devuelve todos los objetivos de control definidos para un periodo
  #
  # * _period_id_::                         ID del periodo
  # * _asocciated_control_objective_ids_::  Arreglo con los IDs de los objetivos
  #                                         de control asociados al informe
  def control_objective_items_for_period(period_id,
      asocciated_control_objective_ids = []) #:doc:
    conditions = ["#{ProcedureControl.table_name}.period_id = :period_id"]
    parameters = {:period_id => period_id}

    unless asocciated_control_objective_ids.blank?
      conditions << 'control_objective_id NOT IN (:control_objective_ids)'
      parameters[:control_objective_ids] = asocciated_control_objective_ids
    end
    procedure_control_subitems = ProcedureControlSubitem.all(
      :joins => {:procedure_control_item => :procedure_control},
      :conditions => [conditions.join(' AND '), parameters]
    )

    procedure_control_subitems.delete_if do |pcs|
      procedure_control_subitems.any? do |pcs2|
        pcs.control_objective_id == pcs2.control_objective_id &&
          pcs.id != pcs2.id
      end
    end

    procedure_control_subitems.map do |pcs|
      control_objective_item = nil

      unless (asocciated_control_objective_ids).include?(pcs.control_objective_id)
        control_objective_item = ControlObjectiveItem.new(
          :control_objective_id => pcs.control_objective_id,
          :control_objective_text => pcs.control_objective_text,
          :controls_attributes => {
            :new_1 => {
              :control => pcs.controls.first.control,
              :effects => pcs.controls.first.effects,
              :design_tests => pcs.controls.first.design_tests,
              :compliance_tests => pcs.controls.first.compliance_tests
            }
          },
          :included_in_review => false
        )
      else
        control_objective_item = @review.control_objective_items.detect do |coi|
          coi.control_objective_id = pcs.control_objective_id
        end

        if control_objective_item
          control_objective_item.included_in_review = true
        end
      end

      control_objective_item
    end.compact
  end

  # Ordena los objetivos de control y modifica el arreglo enviado como parámetro
  #
  # * _control_objective_items_:: Arreglo con los objetivos de control a ordenar
  def sort_control_objective_items!(control_objective_items) #:doc:
    bp_base = 2 ** 64
    pc_base = 2 ** 32

    control_objective_items.sort! do |coi_1, coi_2|
      order_1 = coi_1.control_objective.process_control.best_practice_id *
        bp_base + coi_1.control_objective.process_control.order * pc_base +
        coi_1.control_objective.order
      order_2 = coi_2.control_objective.process_control.best_practice_id *
        bp_base + coi_2.control_objective.process_control.order * pc_base +
        coi_2.control_objective.order
      order_1 <=> order_2
    end
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
      :review_data => :read,
      :download_work_papers => :read,
      :plan_item_data => :read,
      :survey_pdf => :read,
      :auto_complete_for_user => :read,
      :estimated_amount => :read
    })
  end
end