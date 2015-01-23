class FortressesController < ApplicationController
  include AutoCompleteFor::ControlObjectiveItem

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
    parameters = { :boolean_true => true, :boolean_false => false }

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

    @fortresses = Fortress.list.includes(
      :work_papers,
      :control_objective_item => {
        :review => [:period, :plan_item, :conclusion_final_review]
      }
    ).where([@conditions, parameters]).order(
      @order_by || [
        "#{Review.table_name}.identification DESC",
        "#{Fortress.table_name}.review_code ASC"
      ]
    ).page(params[:page])

    respond_to do |format|
      format.html {
        if @fortresses.count == 1 && !@query.blank? && !params[:page]
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
    @fortress = Fortress.list.new(fortress_params)

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

  private
    def set_fortress
      @fortress = Fortress.list.includes(:finding_relations, :work_papers,
        {:finding_user_assignments => :user},
        {:control_objective_item => {:review => :period}}
      ).find(params[:id])
    end

    def fortress_params
      params.require(:fortress).permit(
        :control_objective_item_id, :review_code, :title, :description,
        :origination_date, :lock_version,
        finding_user_assignments_attributes: [
          :id, :user_id, :process_owner, :responsible_auditor, :_destroy
        ],
        work_papers_attributes: [
          :name, :code, :number_of_pages, :description,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_answers_attributes: [
          :id, :answer, :auditor_comments, :commitment_date, :user_id,
          :notify_users, :_destroy, file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_relations_attributes: [:description, :related_finding_id]
      )
    end

    def load_privileges
      @action_privileges.update(
        :auto_complete_for_control_objective_item => :read
      )
    end
end
