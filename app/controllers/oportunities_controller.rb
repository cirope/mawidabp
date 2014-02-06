class OportunitiesController < ApplicationController
  include AutoCompleteFor::User
  include AutoCompleteFor::FindingRelation
  include AutoCompleteFor::ControlObjectiveItem

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_oportunity, only: [
    :show, :edit, :update, :follow_up_pdf, :undo_reiteration
  ]
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista las oportunidades de mejora
  #
  # * GET /oportunities
  # * GET /oportunities.xml
  def index
    @title = t 'oportunity.index_title'
    default_conditions = [
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

    build_search_conditions Oportunity,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @oportunities = Oportunity.list.includes(
      :work_papers,
      :control_objective_item => {
        :review => [:period, :plan_item, :conclusion_final_review]
      }
    ).where([@conditions, parameters]).order(
      @order_by || [
        "#{Review.table_name}.identification DESC",
        "#{Oportunity.table_name}.review_code ASC"
      ]
    ).page(params[:page])

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
      { :control_objective_item_id => params[:control_objective_item] }, {}, true
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
  end

  # Crea una oportunidad de mejora siempre que cumpla con las validaciones.
  #
  # * POST /oportunities
  # * POST /oportunities.xml
  def create
    @title = t 'oportunity.new_title'
    @oportunity = Oportunity.list.new(oportunity_params)

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
  # * PATCH /oportunities/1
  # * PATCH /oportunities/1.xml
  def update
    @title = t 'oportunity.edit_title'

    respond_to do |format|
      Oportunity.transaction do
        if @oportunity.update(oportunity_params)
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
    @oportunity.follow_up_pdf(current_organization)

    redirect_to @oportunity.relative_follow_up_pdf_path
  end

  # Deshace la reiteración de la oportunidad
  #
  # * PATCH /oportunities/undo_reiteration/1
  def undo_reiteration
    @oportunity.undo_reiteration

    respond_to do |format|
      format.html { redirect_to(edit_oportunity_url(@oportunity)) }
      format.xml  { head :ok }
    end
  end

  private
    def set_oportunity
      @oportunity = Oportunity.list.includes(
        :finding_relations, :work_papers,
        {:finding_user_assignments => :user},
        {:control_objective_item => {:review => :period}}
      ).find(params[:id])
    end

    def oportunity_params
      params.require(:oportunity).permit(
        :control_objective_item_id, :review_code, :description, :answer, :audit_comments,
        :cause_analysis, :cause_analysis_date, :correction, :correction_date, :follow_up_date,
        :state, :organization_date, :solution_date, :lock_version, :repeated_of_id,
        finding_user_assignments_attributes: [
          :id, :user_id, :process_owner, :responsible_auditor, :_destroy
        ],
        work_papers_attributes: [
          :id, :name, :code, :number_of_pages, :description, :_destroy,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_answers_attributes: [
          :id, :answer, :auditor_comments, :commitment_date, :user_id,
          :notify_users, :_destroy, file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_relations_attributes: [
          :id, :description, :related_finding_id, :_destroy
        ]
      )
    end

    def load_privileges
      @action_privileges.update(
        :follow_up_pdf => :read,
        :auto_complete_for_user => :read,
        :auto_complete_for_finding_relation => :read,
        :auto_complete_for_control_objective_item => :read,
        :undo_reiteration => :modify
      )
    end
end
