class FortressesController < ApplicationController
  before_action :auth, :load_privileges, :check_privileges
  before_action :set_fortress, only: [:show, :edit, :update]
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista las fortalezas
  #
  # * GET /fortresses
  # * GET /fortresses.xml
  def index
    @title = t 'fortress.index_title'
    default_conditions = [
      "#{Period.table_name}.organization_id = :organization_id",
      [
        [
          "#{ConclusionReview.table_name}.review_id IS NULL",
          "#{Fortress.table_name}.final = :boolean_false"
        ].join(' AND '),
        [
          "#{ConclusionReview.table_name}.review_id IS NOT NULL",
          "#{Fortress.table_name}.final = :boolean_true"
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

    build_search_conditions Fortress,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @fortresses = Fortress.includes(
      :work_papers,
      :control_objective_item => {
        :review => [:period, :plan_item, :conclusion_final_review]
      }
    ).where([@conditions, parameters]).order(
      @order_by || [
        "#{Review.table_name}.identification DESC",
        "#{Fortress.table_name}.review_code ASC"
      ]
    ).paginate(:page => params[:page], :per_page => APP_LINES_PER_PAGE)

    respond_to do |format|
      format.html {
        if @fortresses.size == 1 && !@query.blank? && !params[:page]
          redirect_to fortress_url(@fortresses.first)
        end
      } # index.html.erb
      format.xml  { render :xml => @fortresses }
    end
  end

  # Muestra el detalle de una fortaleza
  #
  # * GET /fortresses/1
  # * GET /fortresses/1.xml
  def show
    @title = t 'fortress.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @fortress }
    end
  end

  # Permite ingresar los datos para crear una nueva fortaleza
  #
  # * GET /fortresses/new
  # * GET /fortresses/new.xml
  def new
    @title = t 'fortress.new_title'
    @fortress = Fortress.new(
      {:control_objective_item_id => params[:control_objective_item]}, {}, true
    )

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @fortress }
    end
  end

  # Recupera los datos para modificar una fortaleza
  #
  # * GET /fortresses/1/edit
  def edit
    @title = t 'fortress.edit_title'
  end

  # Crea una fortaleza siempre que cumpla con las validaciones.
  #
  # * POST /fortresses
  # * POST /fortresses.xml
  def create
    @title = t 'fortress.new_title'
    @fortress = Fortress.new(fortress_params)

    respond_to do |format|
      if @fortress.save
        flash.notice = t 'fortress.correctly_created'
        format.html { redirect_to(edit_fortress_url(@fortress)) }
        format.xml  { render :xml => @fortress, :status => :created, :location => @fortress }
      else
        format.html { render :action => :new }
        format.xml  { render :xml => @fortress.errors, :status => :unprocessable_entity }
      end
    end
  end

  # Actualiza el contenido de una fortaleza siempre que cumpla con
  # las validaciones.
  #
  # * PATCH /fortresses/1
  # * PATCH /fortresses/1.xml
  def update
    @title = t 'fortress.edit_title'

    respond_to do |format|
      Fortress.transaction do
        if @fortress.update(fortress_params)
          flash.notice = t 'fortress.correctly_updated'
          format.html { redirect_to(edit_fortress_url(@fortress)) }
          format.xml  { head :ok }
        else
          format.html { render :action => :edit }
          format.xml  { render :xml => @fortress.errors, :status => :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'fortress.stale_object_error'
    redirect_to :action => :edit
  end

  # * POST /fortresses/auto_complete_for_user
  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Organization.table_name}.id = :organization_id",
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
      [conditions.map {|c| "(#{c})"}.join(' AND '), parameters]
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

  # * POST /fortresses/auto_complete_for_control_objective_item
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
    ).order("#{Review.table_name}.identification ASC").limit(10).references(:review)

    respond_to do |format|
      format.json { render :json => @control_objective_items }
    end
  end

  private
    def set_fortress
      @fortress = Fortress.includes( :finding_relations, :work_papers,
        {:finding_user_assignments => :user},
        {:control_objective_item => {:review => :period}}
      ).where(
        :id => params[:id], Period.table_name => {:organization_id => @auth_organization.id}
      ).first
    end

    def fortress_params
      params.require(:fortress).permit(
        :control_objective_item_id, :review_code, :description, :origination_date,
        :lock_version,
        finding_user_assignments_attributes: [
          :id, :user_id, :process_owner, :responsible_auditor, :_destroy
        ],
        work_papers_attributes: [
          :name, :code, :number_of_pages, :description,
          file_model_attributes: [:file, :file_cache]
        ],
        finding_relations_attributes: [:description, :related_finding_id]
      )
    end

    def load_privileges #:nodoc:
      @action_privileges.update(
        :auto_complete_for_user => :read,
        :auto_complete_for_control_objective_item => :read
      )
    end
end
