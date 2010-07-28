# =Controlador de debilidades
#
# Lista, muestra, crea, modifica y elimina debilidades (#Weakness)
class WeaknessesController < ApplicationController
  before_filter :auth, :load_privileges, :check_privileges
  hide_action :find_with_organization, :load_privileges
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista las debilidades
  #
  # * GET /weaknesses
  # * GET /weaknesses.xml
  def index
    @title = t :'weakness.index_title'
    default_conditions = [
      "#{Period.table_name}.organization_id = :organization_id",
      [
        [
          "#{ConclusionReview.table_name}.review_id IS NULL",
          "#{Weakness.table_name}.final = :boolean_false"
        ].join(' AND '),
        [
          "#{ConclusionReview.table_name}.review_id IS NOT NULL",
          "#{Weakness.table_name}.final = :boolean_true"
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

    build_search_conditions Weakness,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @weaknesses = Weakness.paginate(:page => params[:page],
      :per_page => APP_LINES_PER_PAGE,
      :include => {:control_objective_item =>
          {:review => [:period, :plan_item, :conclusion_final_review]}},
      :conditions => [@conditions, parameters],
      :order => @order_by || [
        "#{Review.table_name}.identification ASC",
        "#{Weakness.table_name}.review_code ASC"
      ].join(', ')
    )

    respond_to do |format|
      format.html {
        if @weaknesses.size == 1 && !@query.blank? && !params[:page]
          redirect_to edit_weakness_path(@weaknesses.first)
        end
      } # index.html.erb
      format.xml  { render :xml => @weaknesses }
    end
  end

  # Muestra el detalle de una debilidad
  #
  # * GET /weaknesses/1
  # * GET /weaknesses/1.xml
  def show
    @title = t :'weakness.show_title'
    @weakness = find_with_organization(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @weakness }
    end
  end

  # Permite ingresar los datos para crear una nueva debilidad
  #
  # * GET /weaknesses/new
  # * GET /weaknesses/new.xml
  def new
    @title = t :'weakness.new_title'
    @weakness = Weakness.new({:control_objective_item_id =>
        params[:control_objective_item]}, true)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @weakness }
    end
  end

  # Recupera los datos para modificar una debilidad
  #
  # * GET /weaknesses/1/edit
  def edit
    @title = t :'weakness.edit_title'
    @weakness = find_with_organization(params[:id])
  end

  # Crea una debilidad siempre que cumpla con las validaciones.
  #
  # * POST /weaknesses
  # * POST /weaknesses.xml
  def create
    @title = t :'weakness.new_title'
    @weakness = Weakness.new(params[:weakness])

    respond_to do |format|
      if @weakness.save
        flash[:notice] = t :'weakness.correctly_created'
        format.html { redirect_to(edit_weakness_path(@weakness)) }
        format.xml  { render :xml => @weakness, :status => :created, :location => @weakness }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @weakness.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de una debilidad siempre que cumpla con las
  # validaciones.
  #
  # * PUT /weaknesses/1
  # * PUT /weaknesses/1.xml
  def update
    @title = t :'weakness.edit_title'
    @weakness = find_with_organization(params[:id])
    params[:weakness][:user_ids] ||= [] unless @weakness.is_in_a_final_review?

    respond_to do |format|
      Weakness.transaction do
        if @weakness.update_attributes(params[:weakness])
          flash[:notice] = t :'weakness.correctly_updated'
          format.html { redirect_to(edit_weakness_path(@weakness)) }
          format.xml  { head :ok }
        else
          format.html { render :action => :edit }
          format.xml  { render :xml => @weakness.errors, :status => :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash[:notice] = t :'weakness.stale_object_error'
    redirect_to :action => :edit
  end

  # Elimina una debilidad
  #
  # * DELETE /weaknesses/1
  # * DELETE /weaknesses/1.xml
  def destroy
    @weakness = find_with_organization(params[:id])
    @weakness.destroy

    respond_to do |format|
      format.html { redirect_to(weaknesses_url) }
      format.xml  { head :ok }
    end
  end

  # Crea el documento de seguimiento de la oportunidad
  #
  # * GET /weaknesses/follow_up_pdf/1
  def follow_up_pdf
    weakness = find_with_organization(params[:id])

    weakness.follow_up_pdf(@auth_organization)

    redirect_to weakness.relative_follow_up_pdf_path
  end

  # * POST /weaknesses/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:user_data][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = ['organizations.id = :organization_id']
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

  # * POST /weaknesses/auto_complete_for_finding_relation
  def auto_complete_for_finding_relation
    @tokens = params[:finding_relation_data][0..100].split(/[y,]/i).uniq.map(
      &:strip)
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

  # Busca la debilidad indicada siempre que pertenezca a la organización. En el
  # caso que no se encuentre (ya sea que no existe una debilidad con ese ID o
  # que no pertenece a la organización con la que se autenticó el usuario)
  # devuelve nil.
  # _id_::  ID de la debilidad que se quiere recuperar
  def find_with_organization(id) #:doc:
    Weakness.first(
      :include => {:control_objective_item => {:review => :period}},
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