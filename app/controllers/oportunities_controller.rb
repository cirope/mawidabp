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
    @title = t :'oportunity.index_title'
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

    if params[:review].to_i > 0
      default_conditions << "#{Review.table_name}.id = :review_id"
      parameters[:review_id] = params[:review].to_i
    end

    build_search_conditions Oportunity,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @oportunities = Oportunity.paginate(:page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => {:control_objective_item =>
          {:review => [:period, :plan_item, :conclusion_final_review]}},
      :conditions => [@conditions, parameters],
      :order => @order_by || [
        "#{Review.table_name}.identification ASC",
        "#{Oportunity.table_name}.review_code ASC"
      ].join(', ')
    )

    respond_to do |format|
      format.html {
        if @oportunities.size == 1 && !@query.blank? && !params[:page]
          redirect_to edit_oportunity_path(@oportunities.first)
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
    @title = t :'oportunity.show_title'
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
    @title = t :'oportunity.new_title'
    @oportunity = Oportunity.new({:control_objective_item_id =>
        params[:control_objective_item]}, true)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @oportunity }
    end
  end

  # Recupera los datos para modificar una oportunidad de mejora
  #
  # * GET /oportunities/1/edit
  def edit
    @title = t :'oportunity.edit_title'
    @oportunity = find_with_organization(params[:id])
  end

  # Crea una oportunidad de mejora siempre que cumpla con las validaciones.
  #
  # * POST /oportunities
  # * POST /oportunities.xml
  def create
    @title = t :'oportunity.new_title'
    @oportunity = Oportunity.new(params[:oportunity])

    respond_to do |format|
      if @oportunity.save
        flash[:notice] = t :'oportunity.correctly_created'
        format.html { redirect_to(edit_oportunity_path(@oportunity)) }
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
    @title = t :'oportunity.edit_title'
    @oportunity = find_with_organization(params[:id])
    params[:oportunity][:user_ids] ||= [] unless @oportunity.is_in_a_final_review?

    respond_to do |format|
      Oportunity.transaction do
        if @oportunity.update_attributes(params[:oportunity])
          flash[:notice] = t :'oportunity.correctly_updated'
          format.html { redirect_to(edit_oportunity_path(@oportunity)) }
          format.xml  { head :ok }
        else
          format.html { render :action => :edit }
          format.xml  { render :xml => @oportunity.errors, :status => :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end
    
  rescue ActiveRecord::StaleObjectError
    flash[:notice] = t :'oportunity.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina una oportunidad de mejora
  #
  # * DELETE /oportunities/1
  # * DELETE /oportunities/1.xml
  def destroy
    @oportunity = find_with_organization(params[:id])
    @oportunity.destroy

    respond_to do |format|
      format.html { redirect_to(oportunities_url) }
      format.xml  { head :ok }
    end
  end

  # Crea el documento de seguimiento de la oportunidad
  #
  # * GET /oportunities/follow_up_pdf/1
  def follow_up_pdf
    oportunity = find_with_organization(params[:id])

    oportunity.follow_up_pdf(@auth_organization)

    redirect_to oportunity.relative_follow_up_pdf_path
  end

  # * POST /oportunities/auto_complete_for_user
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

  # * POST /oportunities/auto_complete_for_finding_relation
  def auto_complete_for_finding_relation
    @tokens = params[:finding_relation_data][0..100].split(
      SPLIT_AND_TERMS_REGEXP).uniq.map(&:strip)
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

      parameters["finding_relation_data_#{i}".to_sym] = "%#{t.downcase}%"
    end
    find_options = {
      :include => {
        :control_objective_item => {
          :review => [:period, :conclusion_final_review]
        }
      },
      :conditions => [conditions.map {|c| "(#{c})"}.join(' AND '), parameters],
      :order => [
        "#{Review.table_name}.identification ASC",
        "#{Finding.table_name}.review_code ASC"
      ].join(','),
      :limit => 5
    }

    @findings = Finding.all(find_options)
  end

  private

  # Busca la oportunidad de mejora indicada siempre que pertenezca a la
  # organización. En el caso que no se encuentre (ya sea que no existe una
  # oportunidad con ese ID o que no pertenece a la organización con la que se
  # autenticó el usuario) devuelve nil.
  # _id_::  ID de la oportunidad que se quiere recuperar
  def find_with_organization(id) #:doc:
    Oportunity.first(
      :include => [:control_objective_item => {:review => :period}],
      :conditions => {
        :id => id,
        Period.table_name => {:organization_id => @auth_organization.id}
      },
      :readonly => false)
  end

  def load_privileges #:nodoc:
    @action_privileges.update({
      :follow_up_pdf => :read,
      :auto_complete_for_user => :read,
      :auto_complete_for_finding_relation => :read
    })
  end
end