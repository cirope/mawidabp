class NonconformitiesController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges
  hide_action :find_with_organization, :load_privileges
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista las no conformidades

  #
  # * GET /nonconformities
  # * GET /nonconformities.xml
  def index
    @title = t 'nonconformity.index_title'
    default_conditions = [
      "#{Period.table_name}.organization_id = :organization_id",
      [
        [
          "#{ConclusionReview.table_name}.review_id IS NULL",
          "#{Nonconformity.table_name}.final = :boolean_false"
        ].join(' AND '),
        [
          "#{ConclusionReview.table_name}.review_id IS NOT NULL",
          "#{Nonconformity.table_name}.final = :boolean_true"
        ].join(' AND ')
      ].map { |condition| "(#{condition})" }.join(' OR ')
    ]
    parameters = {
      :organization_id => @auth_organization.id,
      :boolean_true => true,
      :boolean_false => false
    }

    if params[:control_objective].to_i > 0
      default_conditions << "#{Nonconformity.table_name}.control_objective_item_id = " +
        ":control_objective_id"
      parameters[:control_objective_id] = params[:control_objective].to_i
    end

    if params[:ids]
      default_conditions << "#{Nonconformity.table_name}.id IN(:ids)"
      parameters[:ids] = params[:ids]
    end

    build_search_conditions Nonconformity,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @nonconformities = Nonconformity.includes(
      :work_papers,
      :control_objective_item => {
        :review => [:period, :plan_item, :conclusion_final_review]
      }
    ).where(@conditions, parameters).order(
      @order_by || [
        "#{Review.table_name}.identification DESC",
        "#{Nonconformity.table_name}.review_code ASC"
      ]
    ).paginate(:page => params[:page], :per_page => APP_LINES_PER_PAGE)

    respond_to do |format|
      format.html {
        if @nonconformities.size == 1 && !@query.blank? && !params[:page]
          redirect_to nonconformity_url(@nonconformities.first)
        end
      } # index.html.erb
      format.xml  { render :xml => @nonconformities }
    end
  end

  # Muestra el detalle de una no conformidad
  #
  # * GET /nonconformities/1
  # * GET /nonconformities/1.xml
  def show
    @title = t 'nonconformity.show_title'
    @nonconformity = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @nonconformity }
    end
  end

  # Permite ingresar los datos para crear una nueva no conformidad
  #
  # * GET /nonconformities/new
  # * GET /nonconformities/new.xml
  def new
    @title = t 'nonconformity.new_title'
    @nonconformity = Nonconformity.new(
      {:control_objective_item_id => params[:control_objective_item]}, {}, true
    )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @nonconformity }
    end
  end

  # Recupera los datos para modificar una no conformidad
  #
  # * GET /nonconformities/1/edit
  def edit
    @title = t 'nonconformity.edit_title'
    @nonconformity = find_with_organization(params[:id])
  end

  # Crea una no conformidad siempre que cumpla con las validaciones.
  #
  # * POST /nonconformities
  # * POST /nonconformities.xml
  def create
    @title = t 'nonconformity.new_title'
    @nonconformity = Nonconformity.new(nonconformity_params)

    respond_to do |format|
      if @nonconformity.save
        flash.notice = t 'nonconformity.correctly_created'
        format.html { redirect_to(edit_nonconformity_url(@nonconformity)) }
        format.xml  { render :xml => @nonconformity, :status => :created, :location => @nonconformity }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @nonconformity.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de una no conformidad siempre que cumpla con las
  # validaciones.
  #
  # * PATCH /nonconformities/1
  # * PATCH /nonconformities/1.xml
  def update
    @title = t 'nonconformity.edit_title'
    @nonconformity = find_with_organization(params[:id])

    respond_to do |format|
      Nonconformity.transaction do
        if @nonconformity.update(nonconformity_params)
          flash.notice = t 'nonconformity.correctly_updated'
          format.html { redirect_to(edit_nonconformity_url(@nonconformity)) }
          format.xml  { head :ok }
        else
          format.html { render :action => :edit }
          format.xml  { render :xml => @nonconformity.errors, :status => :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'nonconformity.stale_object_error'
    redirect_to :action => :edit
  end

  # Crea el documento de seguimiento de la no conformidad
  #
  # * GET /nonconformities/follow_up_pdf/1
  def follow_up_pdf
    nonconformity = find_with_organization(params[:id])

    nonconformity.follow_up_pdf(@auth_organization)

    redirect_to nonconformity.relative_follow_up_pdf_path
  end

  # Deshace la reiteración de la no conformidad
  #
  # * PATCH /nonconformities/undo_reiteration/1
  def undo_reiteration
    @nonconformity = find_with_organization(params[:id])
    @nonconformity.undo_reiteration

    respond_to do |format|
      format.html { redirect_to(edit_nonconformity_url(@nonconformity)) }
      format.xml  { head :ok }
    end
  end

  # * GET /nonconformities/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      'organizations.id = :organization_id',
      "#{User.table_name}.hidden = false"
    ]
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
      conditions.map {|c| "(#{c})"}.join(' AND '), parameters
    ).order(
      [
        "#{User.table_name}.last_name ASC",
        "#{User.table_name}.name ASC"
      ]
    ).limit(10).references(:organizations)

    respond_to do |format|
      format.json { render :json => @users }
    end
  end

  # * GET /nonconformities/auto_complete_for_finding_relation
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
      :control_objective_item => {:review => [:period, :conclusion_final_review]}
    ).where(conditions.map {|c| "(#{c})"}.join(' AND '), parameters).order(
      [
        "#{Review.table_name}.identification ASC",
        "#{Finding.table_name}.review_code ASC"
      ]
    ).limit(5)

    respond_to do |format|
      format.json { render :json => @findings }
    end
  end

  # * GET /nonconformities/auto_complete_for_control_objective_item
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
    def nonconformity_params
      params.require(:nonconformity).permit(
        :control_objective_item_id, :review_code, :description, :answer, :audit_comments, 
	:state, :origination_date, :solution_date, :audit_recomendations, :effect, :risk,
	:priority, :follow_up_date, 
	finding_user_assignments_attributes: [
	  :id, :user_id, :process_owner, :_destroy
        ], 
	work_papers_attributes: [
	    :id, :name, :code, :number_of_pages, :description, :_destroy, file_model_attributes: [:file]
        ], 
	finding_answers_attributes: [
	  :id, :answer, :auditor_comments, :commitment_date, :user_id, :notify_users, :_destroy, file_model_attributes: [:file]
	],
	finding_relations_attributes: [
	  :id, :description, :related_finding_id, :_destroy
	]
      )
    end

    # Busca la debilidad indicada siempre que pertenezca a la organización. En el
    # caso que no se encuentre (ya sea que no existe una debilidad con ese ID o
    # que no pertenece a la organización con la que se autenticó el usuario)
    # devuelve nil.
    # _id_::  ID de la debilidad que se quiere recuperar
    def find_with_organization(id) #:doc:
      Nonconformity.includes(
        :finding_relations,
        :work_papers,
        {:finding_user_assignments => :user},
        {:control_objective_item => {:review => :period}}
      ).where(
        :id => id, Period.table_name => {:organization_id => @auth_organization.id}
      ).first
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
