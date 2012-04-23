# =Controlador de oportunidades de mejora
#
# Lista, muestra, crea, modifica y elimina oportunidades de mejora (#Oportunity)
class OportunitiesController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :find_with_organization, :load_privileges
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista las oportunidades de mejora
  #
  # * GET /oportunities
  # * GET /oportunities.xml
  def index
    @title = t 'oportunity.index_title'
    default_conditions = [
      "#{Period.table_name}.organization_id = :organization_id",
      [
        [
          "#{ConclusionReview.table_name}.review_id IS NULL",
          "#{Oportunity.table_name}.final = :boolean_false"
        ].join(' AND '),
        [
          "#{ConclusionReview.table_name}.review_id IS NOT NULL",
          "#{Oportunity.table_name}.final = :boolean_true"
        ].join(' AND ')
      ].map {|condition| "(#{condition})"}.join(' OR ')
    ]
    parameters = {:organization_id => @auth_organization.id,
      :boolean_true => true, :boolean_false => false}
    
    if params[:control_objective].to_i > 0
      default_conditions << "#{Weakness.table_name}.control_objective_item_id = " +
        ":control_objective_id"
      parameters[:control_objective_id] = params[:control_objective].to_i
    end

    if params[:review].to_i > 0
      default_conditions << "#{Review.table_name}.id = :review_id"
      parameters[:review_id] = params[:review].to_i
    end

    build_search_conditions Oportunity,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @oportunities = Oportunity.includes(
      :work_papers,
      :control_objective_item => {
        :review => [:period, :plan_item, :conclusion_final_review]
      }
    ).where([@conditions, parameters]).order(
      @order_by || [
        "#{Review.table_name}.identification DESC",
        "#{Oportunity.table_name}.review_code ASC"
      ]
    ).paginate(:page => params[:page], :per_page => APP_LINES_PER_PAGE)

    respond_to do |format|
      format.html {
        if @oportunities.size == 1 && !@query.blank? && !params[:page]
          redirect_to oportunity_url(@oportunities.first)
        end
      } # index.html.erb
      format.xml  { render :xml => @oportunities }
    end
  end

  # Muestra el detalle de una oportunidad de mejora
  #
  # * GET /oportunities/1
  # * GET /oportunities/1.xml
  def show
    @title = t 'oportunity.show_title'
    @oportunity = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @oportunity }
    end
  end

  # Permite ingresar los datos para crear una nueva oportunidad de mejora
  #
  # * GET /oportunities/new
  # * GET /oportunities/new.xml
  def new
    @title = t 'oportunity.new_title'
    @oportunity = Oportunity.new(
      {:control_objective_item_id => params[:control_objective_item]}, {}, true
    )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @oportunity }
    end
  end

  # Recupera los datos para modificar una oportunidad de mejora
  #
  # * GET /oportunities/1/edit
  def edit
    @title = t 'oportunity.edit_title'
    @oportunity = find_with_organization(params[:id])
  end

  # Crea una oportunidad de mejora siempre que cumpla con las validaciones.
  #
  # * POST /oportunities
  # * POST /oportunities.xml
  def create
    @title = t 'oportunity.new_title'
    @oportunity = Oportunity.new(params[:oportunity])

    respond_to do |format|
      if @oportunity.save
        flash.notice = t 'oportunity.correctly_created'
        format.html { redirect_to(edit_oportunity_url(@oportunity)) }
        format.xml  { render :xml => @oportunity, :status => :created, :location => @oportunity }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @oportunity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de una oportunidad de mejora siempre que cumpla con
  # las validaciones.
  #
  # * PUT /oportunities/1
  # * PUT /oportunities/1.xml
  def update
    @title = t 'oportunity.edit_title'
    @oportunity = find_with_organization(params[:id])

    respond_to do |format|
      Oportunity.transaction do
        if @oportunity.update_attributes(params[:oportunity])
          flash.notice = t 'oportunity.correctly_updated'
          format.html { redirect_to(edit_oportunity_url(@oportunity)) }
          format.xml  { head :ok }
        else
          format.html { render :action => :edit }
          format.xml  { render :xml => @oportunity.errors, :status => :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end
    
  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'oportunity.stale_object_error'
    redirect_to :action => :edit
  end

  # Crea el documento de seguimiento de la oportunidad
  #
  # * GET /oportunities/follow_up_pdf/1
  def follow_up_pdf
    oportunity = find_with_organization(params[:id])

    oportunity.follow_up_pdf(@auth_organization)

    redirect_to oportunity.relative_follow_up_pdf_path
  end
  
  # Deshace la reiteración de la oportunidad
  #
  # * PUT /oportunities/undo_reiteration/1
  def undo_reiteration
    @oportunity = find_with_organization(params[:id])
    @oportunity.undo_reiteration
    
    respond_to do |format|
      format.html { redirect_to(edit_oportunity_url(@oportunity)) }
      format.xml  { head :ok }
    end
  end

  # * POST /oportunities/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
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

      parameters[:"user_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @users = User.includes(:organizations).where(
      [conditions.map {|c| "(#{c})"}.join(' AND '), parameters]
    ).order(
      [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ]
    ).limit(10)
    
    respond_to do |format|
      format.json { render :json => @users }
    end
  end

  # * POST /oportunities/auto_complete_for_finding_relation
  def auto_complete_for_finding_relation
    @tokens = params[:q][0..100].split(SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)
    @tokens.reject! { |t| t.blank? }
    conditions = [
      ("#{Finding.table_name}.id <> :finding_id" unless params[:finding_id].blank?),
      "#{Finding.table_name}.final = :boolean_false",
      "#{Period.table_name}.organization_id = :organization_id",
      [
        "#{ConclusionReview.table_name}.review_id IS NOT NULL",
        ("#{Review.table_name}.id = :review_id" unless params[:review_id].blank?)
      ].compact.join(' OR ')
    ].compact
    parameters = {
      :boolean_false => false,
      :finding_id => params[:finding_id],
      :organization_id => @auth_organization.id,
      :review_id => params[:review_id]
    }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{Finding.table_name}.review_code) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Finding.table_name}.description) LIKE :finding_relation_data_#{i}",
        "LOWER(#{ControlObjectiveItem.table_name}.control_objective_text) LIKE :finding_relation_data_#{i}",
        "LOWER(#{Review.table_name}.identification) LIKE :finding_relation_data_#{i}",
      ].join(' OR ')

      parameters[:"finding_relation_data_#{i}"] = "%#{Unicode::downcase(t)}%"
    end

    @findings = Finding.includes(
      :control_objective_item => {
        :review => [:period, :conclusion_final_review]
      }
    ).where([conditions.map {|c| "(#{c})"}.join(' AND '), parameters]).order(
      [
        "#{Review.table_name}.identification ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    ).limit(5)
    
    respond_to do |format|
      format.json { render :json => @findings }
    end
  end

  # * POST /oportunities/auto_complete_for_control_objective_item
  def auto_complete_for_control_objective_item
    @tokens = params[:q][0..100].split(SEARCH_AND_REGEXP).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Period.table_name}.organization_id = :organization_id",
      "#{ConclusionReview.table_name}.review_id IS NULL",
      "#{ControlObjectiveItem.table_name}.review_id = :review_id"
    ]
    parameters = {
      :organization_id => @auth_organization.id,
      :review_id => params[:review_id].to_i
    }

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{ControlObjectiveItem.table_name}.control_objective_text) LIKE :control_objective_item_data_#{i}"
      ].join(' OR ')

      parameters[:"control_objective_item_data_#{i}"] =
        "%#{Unicode::downcase(t)}%"
    end

    @control_objective_items = ControlObjectiveItem.includes(
      :review => [:period, :conclusion_final_review]
    ).where(
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order("#{Review.table_name}.identification ASC").limit(10)
    
    respond_to do |format|
      format.json { render :json => @control_objective_items }
    end
  end

  private

  # Busca la oportunidad de mejora indicada siempre que pertenezca a la
  # organización. En el caso que no se encuentre (ya sea que no existe una
  # oportunidad con ese ID o que no pertenece a la organización con la que se
  # autenticó el usuario) devuelve nil.
  # _id_::  ID de la oportunidad que se quiere recuperar
  def find_with_organization(id) #:doc:
    Oportunity.includes(
      :finding_relations,
      :work_papers,
      {:finding_user_assignments => :user},
      {:control_objective_item => {:review => :period}}
    ).where(
      :id => id, Period.table_name => {:organization_id => @auth_organization.id}
    ).first(:readonly => false)
  end

  def load_privileges #:nodoc:
    @action_privileges.update(
      :follow_up_pdf => :read,
      :auto_complete_for_user => :read,
      :auto_complete_for_finding_relation => :read,
      :auto_complete_for_control_objective_item => :read,
      :undo_reiteration => :modify
    )
  end
end