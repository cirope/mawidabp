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
    @title = t 'conclusion_final_review.index_title'
    default_conditions = {
      "#{Period.table_name}.organization_id" => @auth_organization.id
    }
    
    build_search_conditions ConclusionFinalReview, default_conditions
    
    order = @order_by || "issue_date DESC"
    order << ", #{ConclusionFinalReview.table_name}.created_at DESC"

    @conclusion_final_reviews = ConclusionFinalReview.includes(
      :review => [:period, { :plan_item => :business_unit }]
    ).where(@conditions).order(order).paginate(
      :page => params[:page], :per_page => APP_LINES_PER_PAGE
    )

    respond_to do |format|
      format.html {
        if @conclusion_final_reviews.size == 1 && !@query.blank? &&
            !params[:page]
          redirect_to(
            conclusion_final_review_url(@conclusion_final_reviews.first)
          )
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
    @title = t 'conclusion_final_review.show_title'
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
      @title = t 'conclusion_final_review.new_title'
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
      conclusion_final_review = ConclusionFinalReview.where(
        :review_id => params[:review]).first
      
      redirect_to edit_conclusion_final_review_url(conclusion_final_review)
    end
  end

  # Recupera los datos para modificar un informe definitivo
  #
  # * GET /conclusion_final_reviews/1/edit
  def edit
    @title = t 'conclusion_final_review.edit_title'
    @conclusion_final_review = find_with_organization(params[:id])
  end

  # Crea un nuevo informe definitivo siempre que cumpla con las validaciones.
  #
  # * POST /conclusion_final_reviews
  # * POST /conclusion_final_reviews.xml
  def create
    @title = t 'conclusion_final_review.new_title'
    @conclusion_final_review = ConclusionFinalReview.new(
      params[:conclusion_final_review], {}, false)

    respond_to do |format|
      if @conclusion_final_review.save
        flash.notice = t 'conclusion_final_review.correctly_created'
        format.html { redirect_to(conclusion_final_reviews_url) }
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
    @title = t 'conclusion_final_review.edit_title'
    @conclusion_final_review = find_with_organization(params[:id])

    respond_to do |format|
      if @conclusion_final_review.update_attributes(
          params[:conclusion_final_review])
        flash.notice = t 'conclusion_final_review.correctly_updated'
        format.html { redirect_to(conclusion_final_reviews_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => :edit }
        format.xml  { render :xml => @conclusion_final_review.errors, :status => :unprocessable_entity }
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'conclusion_final_review.stale_object_error'
    redirect_to :action => :edit
  end

  # Exporta el informe en formato PDF
  #
  # * GET /conclusion_final_reviews/export_to_pdf/1
  def export_to_pdf
    @conclusion_final_review = find_with_organization(params[:id])
    
    @conclusion_final_review.to_pdf(@auth_organization, params[:export_options])

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
    @title = t 'conclusion_final_review.bundle_title'
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
    @title = t 'conclusion_final_review.send_by_email'
    @conclusion_final_review = find_with_organization(params[:id])
  end

  # Envia por correo el informe a los usuarios indicados
  #
  # * POST /conclusion_final_reviews/send_by_email/1
  def send_by_email
    @title = t 'conclusion_final_review.send_by_email'
    @conclusion_final_review = find_with_organization(params[:id])

    users = []

    if params[:conclusion_review]
      include_score_sheet =
        params[:conclusion_review][:include_score_sheet] == '1'
      include_global_score_sheet =
        params[:conclusion_review][:include_global_score_sheet] == '1'
      note = params[:conclusion_review][:email_note]
    end

    @conclusion_final_review.to_pdf(@auth_organization, params[:export_options])

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
        :include_score_sheet => include_score_sheet,
        :include_global_score_sheet => include_global_score_sheet
      }
      
        if user && !users.include?(user)
          @conclusion_final_review.send_by_email_to(user, send_options)

          users << user
        end
        
        if user && user_data[:questionnaire_id].present?
          @conclusion_final_review.polls.create!(
            :questionnaire_id => user_data[:questionnaire_id],
            :user_id => user.id
          )
        end
      end
    
    unless users.blank?
      flash.notice = t('conclusion_review.review_sended')

      redirect_to edit_conclusion_final_review_url(@conclusion_final_review)
    else
      render :action => :compose_email
    end
  end

  # Lista las informes en un PDF
  #
  # * GET /conclusion_final_reviews/export_to_pdf
  def export_list_to_pdf
    default_conditions = {
      "#{Period.table_name}.organization_id" => @auth_organization.id
    }

    build_search_conditions ConclusionFinalReview, default_conditions

    conclusion_final_reviews = ConclusionFinalReview.includes(
      :review => [:period, { :plan_item => :business_unit }]
    ).where(@conditions).order(@order_by || 'issue_date DESC')

    pdf = PDF::Writer.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization
    pdf.add_title t('conclusion_final_review.index_title')

    column_order = [
      ['period', Review.human_attribute_name(:period_id), 10],
      ['identification', Review.human_attribute_name(:identification), 10],
      ['business_unit', PlanItem.human_attribute_name(:business_unit_id), 30],
      ['project', PlanItem.human_attribute_name(:project), 30],
      ['issue_date', ConclusionDraftReview.human_attribute_name(:issue_date), 10],
      ['close_date', ConclusionDraftReview.human_attribute_name(:close_date), 10],
    ]
    columns = {}
    column_data = []

    column_order.each do |col_name, col_title, col_with|
      columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
        c.heading = col_title
        c.width = pdf.percent_width col_with
      end
    end

    conclusion_final_reviews.each do |cfr|
      column_data << {
        'period' => cfr.review.period.number.to_s.to_iso,
        'identification' => cfr.review.identification.to_iso,
        'business_unit' => cfr.review.plan_item.business_unit.name.to_iso,
        'project' => cfr.review.plan_item.project.to_iso,
        'issue_date' => "<b>#{cfr.issue_date ? l(cfr.issue_date, :format => :minimal) : ''}</b>".to_iso,
        'close_date' => (cfr.close_date ? l(cfr.close_date, :format => :minimal) : '').to_iso,
      }
    end

    unless @columns.blank? || @query.blank?
      pdf.move_pointer PDF_FONT_SIZE
      pointer_moved = true
      filter_columns = @columns.map do |c|
        column_name = column_order.detect { |co| co[0] == c }
        "<b>#{column_name[1]}</b>"
      end

      pdf.text t('conclusion_final_review.pdf.filtered_by',
        :query => @query.map {|q| "<b>#{q}</b>"}.join(', '),
        :columns => filter_columns.to_sentence, :count => @columns.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round
    end

    unless @order_by_column_name.blank?
      pdf.move_pointer PDF_FONT_SIZE unless pointer_moved
      pdf.text t('conclusion_final_review.pdf.sorted_by',
        :column => "<b>#{@order_by_column_name}</b>"),
        :font_size => (PDF_FONT_SIZE * 0.75).round
    end

    pdf.move_pointer PDF_FONT_SIZE

    unless column_data.blank?
      PDF::SimpleTable.new do |table|
        table.width = pdf.page_usable_width
        table.columns = columns
        table.data = column_data
        table.column_order = column_order.map(&:first)
        table.split_rows = true
        table.font_size = (PDF_FONT_SIZE * 0.75).round
        table.shade_color = Color::RGB.from_percentage(95, 95, 95)
        table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
        table.heading_font_size = (PDF_FONT_SIZE * 0.75).round
        table.shade_headings = true
        table.position = :left
        table.orientation = :right
        table.render_on pdf
      end
    end

    pdf_name = t 'conclusion_final_review.pdf.pdf_name'

    pdf.custom_save_as(pdf_name, ConclusionFinalReview.table_name)

    redirect_to PDF::Writer.relative_path(pdf_name, ConclusionFinalReview.table_name)
  end

  # Método para el autocompletado de usuarios
  #
  # * POST /reviews/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = ['organizations.id = :organization_id']
    parameters = {:organization_id => @auth_organization.id}
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(users.name) LIKE :user_data_#{i}",
        "LOWER(users.last_name) LIKE :user_data_#{i}",
        "LOWER(users.email) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters[:"user_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @users = User.includes(:organizations).where(
      [conditions.map {|c| "(#{c})"}.join(' AND '), parameters]
    ).order(
      ["#{User.table_name}.last_name ASC", "#{User.table_name}.name ASC"]
    ).limit(10)
    
    respond_to do |format|
      format.json { render :json => @users }
    end
  end

  private

  # Busca el informe definitivo indicado siempre que pertenezca a la organización.
  # En el caso que no se encuentre (ya sea que no existe un informe con ese ID o
  # que no pertenece a la organización con la que se autenticó el usuario)
  # devuelve nil.
  # _id_::  ID del informe definitivo que se quiere recuperar
  def find_with_organization(id) #:doc:
    ConclusionFinalReview.includes(
      :review => [
        :period,
        :plan_item,
        {
          :control_objective_items => [
            :control, :final_weaknesses, :final_oportunities
          ]
        }
      ]
    ).where(
      :id => id,
      Period.table_name => {:organization_id => @auth_organization.id}
    ).first(:readonly => false)
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
        :export_to_pdf => :read,
        :score_sheet => :read,
        :download_work_papers => :read,
        :bundle => :read,
        :create_bundle => :read,
        :export_list_to_pdf => :read,
        :auto_complete_for_user => :read,
        :compose_email => :modify,
        :send_by_email => :modify
      })
  end
end