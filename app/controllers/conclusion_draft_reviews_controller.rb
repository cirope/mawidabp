# =Controlador de informes borradores
#
# Lista, muestra, crea, modifica y elimina informes borradores
# (#ConclusionDraftReview)
class ConclusionDraftReviewsController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :find_with_organization, :load_privileges
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista los informes borradores
  #
  # * GET /conclusion_draft_reviews
  # * GET /conclusion_draft_reviews.xml
  def index
    @title = t :'conclusion_draft_review.index_title'
    default_conditions = {
      "#{Period.table_name}.organization_id" => @auth_organization.id
    }

    build_search_conditions ConclusionDraftReview, default_conditions

    @conclusion_draft_reviews = ConclusionDraftReview.paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE,
      :include => { :review => [:period, { :plan_item => :business_unit }] },
      :conditions => @conditions,
      :order => 'issue_date DESC')

    respond_to do |format|
      format.html {
        if @conclusion_draft_reviews.size == 1 && !@query.blank? &&
            !params[:page] && !@conclusion_draft_reviews.first.has_final_review?
          redirect_to edit_conclusion_draft_review_path(
            @conclusion_draft_reviews.first)
        end
      }
      format.xml  { render :xml => @conclusion_draft_reviews }
    end
  end

  # Muestra el detalle de un informe borrador
  #
  # * GET /conclusion_draft_reviews/1
  # * GET /conclusion_draft_reviews/1.xml
  def show
    @title = t :'conclusion_draft_review.show_title'
    @conclusion_draft_review = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @conclusion_draft_review }
    end
  end

  # Permite ingresar los datos para crear un nuevo informe borrador
  #
  # * GET /conclusion_draft_reviews/new
  # * GET /conclusion_draft_reviews/new.xml
  def new
    @title = t :'conclusion_draft_review.new_title'
    @conclusion_draft_review = ConclusionDraftReview.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @conclusion_draft_review }
    end
  end

  # Recupera los datos para modificar un informe borrador
  #
  # * GET /conclusion_draft_reviews/1/edit
  def edit
    @title = t :'conclusion_draft_review.edit_title'
    @conclusion_draft_review = find_with_organization(params[:id])
  end

  # Crea un nuevo informe borrador siempre que cumpla con las validaciones.
  #
  # * POST /conclusion_draft_reviews
  # * POST /conclusion_draft_reviews.xml
  def create
    @title = t :'conclusion_draft_review.new_title'
    @conclusion_draft_review = ConclusionDraftReview.new(
      params[:conclusion_draft_review])

    respond_to do |format|
      if @conclusion_draft_review.save
        flash[:notice] = t :'conclusion_draft_review.correctly_created'
        format.html { redirect_to(conclusion_draft_reviews_path) }
        format.xml  { render :xml => @conclusion_draft_review, :status => :created, :location => @conclusion_draft_review }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @conclusion_draft_review.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de un informe borrador siempre que cumpla con las
  # validaciones.
  #
  # * PUT /conclusion_draft_reviews/1
  # * PUT /conclusion_draft_reviews/1.xml
  def update
    @title = t :'conclusion_draft_review.edit_title'
    @conclusion_draft_review = find_with_organization(params[:id])

    respond_to do |format|
      if @conclusion_draft_review.update_attributes(
          params[:conclusion_draft_review])
        flash[:notice] = t :'conclusion_draft_review.correctly_updated'
        format.html { redirect_to(conclusion_draft_reviews_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @conclusion_draft_review.errors, :status => :unprocessable_entity }
      end
    end

    rescue ActiveRecord::StaleObjectError
      flash[:alert] = t :'conclusion_draft_review.stale_object_error'
      redirect_to :action => :edit
  end

  # Exporta el informe en formato PDF
  #
  # * GET /conclusion_draft_reviews/export_to_pdf/1
  def export_to_pdf
    @conclusion_draft_review = find_with_organization(params[:id])

    @conclusion_draft_review.to_pdf(@auth_organization)

    respond_to do |format|
      format.html { redirect_to @conclusion_draft_review.relative_pdf_path }
      format.xml  { head :ok }
    end
  end

  # Crea la planilla de calificación del informe en formato PDF
  #
  # * GET /conclusion_draft_reviews/score_sheet/1
  def score_sheet
    @conclusion_draft_review = find_with_organization(params[:id])
    review = @conclusion_draft_review.review

    if params[:global].blank?
      review.score_sheet(@auth_organization, true)

      redirect_to review.relative_score_sheet_path
    else
      review.global_score_sheet(@auth_organization, true)

      redirect_to review.relative_global_score_sheet_path
    end
  end

  # Devuelve los papeles de trabajo del informe
  #
  # * GET /conclusion_draft_reviews/download_work_papers/1
  def download_work_papers
    @conclusion_draft_review = find_with_organization(params[:id])
    review = @conclusion_draft_review.review

    review.zip_all_work_papers @auth_organization

    redirect_to review.relative_work_papers_zip_path
  end

  # Muestra las opciones editables del legajo
  #
  # * GET /conclusion_draft_reviews/bundle/1
  def bundle
    @title = t :'conclusion_draft_review.bundle_title'
    @conclusion_draft_review = find_with_organization(params[:id])
  end

  # Crea el legajo completo del informe
  #
  # * POST /conclusion_draft_reviews/create_bundle
  def create_bundle
    @conclusion_draft_review = find_with_organization(params[:id])

    @conclusion_draft_review.create_bundle_zip @auth_organization,
      params[:index_items]

    redirect_to @conclusion_draft_review.relative_bundle_zip_path
  end

  # Confecciona el correo con el informe
  #
  # * GET /conclusion_draft_reviews/compose_email/1
  def compose_email
    @title = t :'conclusion_draft_review.send_by_email'
    @conclusion_draft_review = find_with_organization(params[:id])
  end

  # Envia por correo el informe a los usuarios indicados
  #
  # * POST /conclusion_draft_reviews/send_by_email/1
  def send_by_email
    @title = t :'conclusion_draft_review.send_by_email'
    @conclusion_draft_review = find_with_organization(params[:id])

    if @conclusion_draft_review.try(:review).try(:can_be_sended?) &&
        !@conclusion_draft_review.has_final_review?
      users = []

      if params[:conclusion_review]
        include_score_sheet =
          params[:conclusion_review][:include_score_sheet] == '1'
        include_global_score_sheet =
          params[:conclusion_review][:include_global_score_sheet] == '1'
        note = params[:conclusion_review][:email_note]
      end

      @conclusion_draft_review.to_pdf(@auth_organization)

      if include_score_sheet
        @conclusion_draft_review.review.score_sheet @auth_organization, true
      end

      if include_global_score_sheet
        @conclusion_draft_review.review.global_score_sheet(@auth_organization,
          true)
      end

      (params[:user].try(:values) || []).each do |user_data|
        user = User.find(user_data[:id]) if user_data[:id]
        send_options = {
          :note => note,
          :notify => (user_data[:must_confirm] == '1'),
          :include_score_sheet => include_score_sheet,
          :include_global_score_sheet => include_global_score_sheet
        }

        if user && !users.include?(user)
          @conclusion_draft_review.send_by_email_to(user, send_options)

          users << user
        end
      end

      unless users.blank?
        flash[:notice] = t(:'conclusion_review.review_sended')

        redirect_to edit_conclusion_draft_review_path(
          @conclusion_draft_review)
      else
        render :action => :compose_email
      end
    elsif @conclusion_draft_review.try(:review)
      flash[:alert] = t(:'conclusion_review.review_not_approved')
      render :action => :compose_email
    else
      redirect_to conclusion_draft_reviews_path
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

  def check_for_approval
    if params[:id] && params[:id].to_i > 0
      review = Review.first(
        :include => :period,
        :conditions =>{
          :id => params[:id],
          "#{Period.table_name}.organization_id" => @auth_organization.id
        }
      )

      render :json => {
        :approved => review.is_approved?,
        :can_be_approved_by_force => review.can_be_approved_by_force,
        :errors => review.approval_errors
      }.to_json
    else
      render :json => ''
    end
  end

  private

  # Busca el informe borrador indicado siempre que pertenezca a la organización.
  # En el caso que no se encuentre (ya sea que no existe un informe con ese ID o
  # que no pertenece a la organización con la que se autenticó el usuario)
  # devuelve nil.
  # _id_::  ID del informe borrador que se quiere recuperar
  def find_with_organization(id) #:doc:
    conclusion_draft_review = ConclusionDraftReview.first(
      :include => {:review => :period},
      :conditions => [
        [
          "#{ConclusionDraftReview.table_name}.id = :id",
          "#{Period.table_name}.organization_id = :organization_id"
        ].join(' AND '),
        {:id => id, :organization_id => @auth_organization.id}
      ],
      :readonly => false
    )

    conclusion_draft_review.has_final_review? ? nil : conclusion_draft_review
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
        :export_to_pdf => :read,
        :score_sheet => :read,
        :download_work_papers => :read,
        :bundle => :read,
        :create_bundle => :read,
        :auto_complete_for_user => :read,
        :check_for_approval => :read,
        :compose_email => :modify,
        :send_by_email => :modify
      })
  end
end