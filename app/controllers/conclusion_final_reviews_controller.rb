# =Controlador de informes definitivos
#
# Lista, muestra, crea, modifica y elimina informes definitivos
# (#ConclusionFinalReview)
class ConclusionFinalReviewsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :find_with_organization, :load_privileges
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista los informes definitivos
  #
  # * GET /conclusion_final_reviews
  # * GET /conclusion_final_reviews.xml
  def index
    @title = t :'conclusion_final_review.index_title'
    default_conditions = {
      "#{Period.table_name}.organization_id" => @auth_organization.id
    }

    build_search_conditions ConclusionFinalReview, default_conditions

    @conclusion_final_reviews = ConclusionFinalReview.paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE,
      :include => { :review => [:period, { :plan_item => :business_unit }] },
      :conditions => @conditions,
      :order => 'issue_date DESC')

    respond_to do |format|
      format.html {
        if @conclusion_final_reviews.size == 1 && !@query.blank? &&
            !params[:page]
          redirect_to edit_conclusion_final_review_path(
            @conclusion_final_reviews.first)
        end
      }
      format.xml  { render :xml => @conclusion_final_reviews }
    end
  end

  # Muestra el detalle de un informe definitivo
  #
  # * GET /conclusion_final_reviews/1
  # * GET /conclusion_final_reviews/1.xml
  def show
    @title = t :'conclusion_final_review.show_title'
    @conclusion_final_review = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @conclusion_final_review }
    end
  end

  # Permite ingresar los datos para crear un nuevo informe definitivo
  #
  # * GET /conclusion_final_reviews/new
  # * GET /conclusion_final_reviews/new.xml
  # * GET /conclusion_final_reviews/new.json
  def new
    unless ConclusionFinalReview.exists?(:review_id => params[:review])
      @title = t :'conclusion_final_review.new_title'
      @conclusion_final_review = ConclusionFinalReview.new(
        :review_id => params[:review])

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @conclusion_final_review }
        format.json { render :json => @conclusion_final_review.to_json(
            :include => {:review => {
                :only => [],
                :methods => :score_text,
                :include => {
                  :business_unit => {:only => :name},
                  :plan_item => {:only => :project}
                },
              }
            },
            :only => [:conclusion, :applied_procedures])
        }
      end
    else
      conclusion_final_review = ConclusionFinalReview.first(:conditions =>
          {:review_id => params[:review]})
      
      redirect_to edit_conclusion_final_review_path(conclusion_final_review)
    end
  end

  # Recupera los datos para modificar un informe definitivo
  #
  # * GET /conclusion_final_reviews/1/edit
  def edit
    @title = t :'conclusion_final_review.edit_title'
    @conclusion_final_review = find_with_organization(params[:id])
  end

  # Crea un nuevo informe definitivo siempre que cumpla con las validaciones.
  #
  # * POST /conclusion_final_reviews
  # * POST /conclusion_final_reviews.xml
  def create
    @title = t :'conclusion_final_review.new_title'
    @conclusion_final_review = ConclusionFinalReview.new(
      params[:conclusion_final_review], false)

    respond_to do |format|
      if @conclusion_final_review.save
        flash[:notice] = t :'conclusion_final_review.correctly_created'
        format.html { redirect_to(conclusion_final_reviews_path) }
        format.xml  { render :xml => @conclusion_final_review, :status => :created, :location => @conclusion_final_review }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @conclusion_final_review.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un informe definitivo siempre que cumpla con las
  # validaciones.
  #
  # * PUT /conclusion_final_reviews/1
  # * PUT /conclusion_final_reviews/1.xml
  def update
    @title = t :'conclusion_final_review.edit_title'
    @conclusion_final_review = find_with_organization(params[:id])

    respond_to do |format|
      if @conclusion_final_review.update_attributes(
          params[:conclusion_final_review])
        flash[:notice] = t :'conclusion_final_review.correctly_updated'
        format.html { redirect_to(conclusion_final_reviews_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @conclusion_final_review.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash[:alert] = t :'conclusion_final_review.stale_object_error'
    redirect_to :action => :edit
  end

  # Exporta el informe en formato PDF
  #
  # * GET /conclusion_final_reviews/export_to_pdf/1
  def export_to_pdf
    @conclusion_final_review = find_with_organization(params[:id])
    
    @conclusion_final_review.to_pdf(@auth_organization)

    respond_to do |format|
      format.html { redirect_to @conclusion_final_review.relative_pdf_path }
      format.xml  { head :ok }
    end
  end

  # Crea la planilla de calificación del informe en formato PDF
  #
  # * GET /conclusion_final_reviews/score_sheet/1
  def score_sheet
    @conclusion_final_review = find_with_organization(params[:id])
    review = @conclusion_final_review.review
    
    if params[:global].blank?
      review.score_sheet(@auth_organization)

      redirect_to review.relative_score_sheet_path
    else
      review.global_score_sheet(@auth_organization)

      redirect_to review.relative_global_score_sheet_path
    end
  end

  # Devuelve los papeles de trabajo del informe
  #
  # * GET /conclusion_final_reviews/download_work_papers/1
  def download_work_papers
    @conclusion_final_review = find_with_organization(params[:id])
    review = @conclusion_final_review.review

    review.zip_all_work_papers @auth_organization

    redirect_to review.relative_work_papers_zip_path
  end

  # Muestra las opciones editables del legajo
  #
  # * GET /conclusion_final_reviews/bundle/1
  def bundle
    @title = t :'conclusion_final_review.bundle_title'
    @conclusion_final_review = find_with_organization(params[:id])
  end

  # Crea el legajo completo del informe
  #
  # * POST /conclusion_final_reviews/create_bundle
  def create_bundle
    @conclusion_final_review = find_with_organization(params[:id])

    @conclusion_final_review.create_bundle_zip @auth_organization,
      params[:index_items]

    redirect_to @conclusion_final_review.relative_bundle_zip_path
  end

  # Confecciona el correo con el informe
  #
  # * GET /conclusion_final_reviews/compose_email/1
  def compose_email
    @title = t :'conclusion_final_review.send_by_email'
    @conclusion_final_review = find_with_organization(params[:id])
  end

  # Envia por correo el informe a los usuarios indicados
  #
  # * POST /conclusion_final_reviews/send_by_email/1
  def send_by_email
    @title = t :'conclusion_final_review.send_by_email'
    @conclusion_final_review = find_with_organization(params[:id])

    users = []

    if params[:conclusion_review]
      include_score_sheet =
        params[:conclusion_review][:include_score_sheet] == '1'
      include_global_score_sheet =
        params[:conclusion_review][:include_global_score_sheet] == '1'
      note = params[:conclusion_review][:email_note]
    end

    @conclusion_final_review.to_pdf(@auth_organization)

    if include_score_sheet
      @conclusion_final_review.review.score_sheet @auth_organization, false
    end

    if include_global_score_sheet
      @conclusion_final_review.review.global_score_sheet(@auth_organization,
        false)
    end

    (params[:user].try(:values) || []).each do |user_data|
      user = User.find(user_data[:id]) if user_data[:id]
      send_options = {
        :note => note,
        :notify => false,
        :include_score_sheet => include_score_sheet,
        :include_global_score_sheet => include_global_score_sheet
      }

      if user && !users.include?(user)
        @conclusion_final_review.send_by_email_to(user, send_options)

        users << user
      end
    end

    unless users.blank?
      flash[:notice] = t(:'conclusion_review.review_sended')

      redirect_to edit_conclusion_final_review_path(@conclusion_final_review)
    else
      render :action => :compose_email
    end
  end

  # Método para el autocompletado de usuarios
  #
  # * POST /reviews/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:user_data][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = ['organizations.id = :organization_id']
    parameters = {:organization_id => @auth_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(users.name) LIKE :user_data_#{i}",
        "LOWER(users.last_name) LIKE :user_data_#{i}",
        "LOWER(users.email) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters["user_data_#{i}".to_sym] = "%#{t.downcase}%"
    end
    find_options = {
      :include => :organizations,
      :conditions => [conditions.map {|c| "(#{c})"}.join(' AND '), parameters],
      :order => ['users.last_name ASC', 'users.name ASC'].join(','),
      :limit => 10
    }

    @users = User.all(find_options)
  end

  private

  # Busca el informe definitivo indicado siempre que pertenezca a la organización.
  # En el caso que no se encuentre (ya sea que no existe un informe con ese ID o
  # que no pertenece a la organización con la que se autenticó el usuario)
  # devuelve nil.
  # _id_::  ID del informe definitivo que se quiere recuperar
  def find_with_organization(id) #:doc:
    ConclusionFinalReview.first(
      :include => {:review => :period},
      :conditions => {
        :id => id,
        Period.table_name => {:organization_id => @auth_organization.id}
      },
      :readonly => false)
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
        :export_to_pdf => :read,
        :score_sheet => :read,
        :download_work_papers => :read,
        :bundle => :read,
        :create_bundle => :read,
        :auto_complete_for_user => :read,
        :compose_email => :modify,
        :send_by_email => :modify
      })
  end
end