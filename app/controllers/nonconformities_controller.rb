class NonconformitiesController < ApplicationController
  include AutoCompleteFor::FindingRelation
  include AutoCompleteFor::ControlObjectiveItem

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_nonconformity, only: [
    :show, :edit, :update, :follow_up_pdf, :undo_reiteration
  ]
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista las no conformidades
  #
  # * GET /nonconformities
  # * GET /nonconformities.xml
  def index
    @title = t 'nonconformity.index_title'
    default_conditions = [
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
    parameters = { :boolean_true => true, :boolean_false => false }

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

    @nonconformities = Nonconformity.list.includes(
      :work_papers,
      :control_objective_item => {
        :review => [:period, :plan_item, :conclusion_final_review]
      }
    ).where(@conditions, parameters).order(
      @order_by || [
        "#{Review.table_name}.identification DESC",
        "#{Nonconformity.table_name}.review_code ASC"
      ]
    ).page(params[:page])

    respond_to do |format|
      format.html {
        if @nonconformities.count == 1 && !@query.blank? && !params[:page]
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
  end

  # Crea una no conformidad siempre que cumpla con las validaciones.
  #
  # * POST /nonconformities
  # * POST /nonconformities.xml
  def create
    @title = t 'nonconformity.new_title'
    @nonconformity = Nonconformity.list.new(nonconformity_params)

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
    @nonconformity.follow_up_pdf(current_organization)
    redirect_to @nonconformity.relative_follow_up_pdf_path
  end

  # Deshace la reiteración de la no conformidad
  #
  # * PATCH /nonconformities/undo_reiteration/1
  def undo_reiteration
    @nonconformity.undo_reiteration

    respond_to do |format|
      format.html { redirect_to(edit_nonconformity_url(@nonconformity)) }
      format.xml  { head :ok }
    end
  end

  private
    def nonconformity_params
      params.require(:nonconformity).permit(
        :control_objective_item_id, :review_code, :description, :answer, :audit_comments,
        :cause_analysis, :cause_analysis_date, :correction, :correction_date,
        :state, :origination_date, :solution_date, :audit_recommendations, :effect, :risk,
        :priority, :follow_up_date, :lock_version, :repeated_of_id,
        finding_user_assignments_attributes: [
          :id, :user_id, :process_owner, :responsible_auditor, :_destroy
        ],
        work_papers_attributes: [
          :id, :name, :code, :number_of_pages, :description, :_destroy,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_answers_attributes: [
          :id, :answer, :auditor_comments, :commitment_date, :user_id,
          :notify_users, :_destroy,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_relations_attributes: [
          :id, :description, :related_finding_id, :_destroy
        ]
      )
    end

    def set_nonconformity
      @nonconformity = Nonconformity.list.includes(
        :finding_relations, :work_papers,
        {:finding_user_assignments => :user},
        {:control_objective_item => {:review => :period}}
      ).find(params[:id])
    end

    def load_privileges
      @action_privileges.update(
        :follow_up_pdf => :read,
        :auto_complete_for_finding_relation => :read,
        :auto_complete_for_control_objective_item => :read,
        :undo_reiteration => :modify
      )
    end
end
