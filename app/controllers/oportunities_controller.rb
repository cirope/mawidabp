 class OportunitiesController < ApplicationController
  include AutoCompleteFor::ControlObjectiveItem
  include AutoCompleteFor::FindingRelation
  include AutoCompleteFor::Tagging

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_oportunity, only: [
    :show, :edit, :update, :undo_reiteration
  ]
  layout proc{ |controller| controller.request.xhr? ? false : 'application' }

  # Lista las oportunidades de mejora
  #
  # * GET /oportunities
  def index
    @title = t 'oportunity.index_title'
    default_conditions = [
      [
        [
          "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NULL",
          "#{Oportunity.quoted_table_name}.#{Oportunity.qcn('final')} = :boolean_false"
        ].join(' AND '),
        [
          "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('review_id')} IS NOT NULL",
          "#{Oportunity.quoted_table_name}.#{Oportunity.qcn('final')} = :boolean_true"
        ].join(' AND ')
      ].map {|condition| "(#{condition})"}.join(' OR ')
    ]
    parameters = { :boolean_true => true, :boolean_false => false }

    if params[:control_objective].to_i > 0
      default_conditions << "#{Weakness.quoted_table_name}.#{Weakness.qcn('control_objective_item_id')} = " +
        ":control_objective_id"
      parameters[:control_objective_id] = params[:control_objective].to_i
    end

    if params[:review].to_i > 0
      default_conditions << "#{Review.quoted_table_name}.#{Review.qcn('id')} = :review_id"
      parameters[:review_id] = params[:review].to_i
    end

    build_search_conditions Oportunity,
      default_conditions.map { |c| "(#{c})" }.join(' AND ')

    @oportunities = Oportunity.list.includes(
      :work_papers, :tags,
      :control_objective_item => {
        :review => [:period, :plan_item, :conclusion_final_review]
      }
    ).where([@conditions, parameters]).order(
      @order_by || [
        "#{Review.quoted_table_name}.#{Review.qcn('identification')} DESC",
        "#{Oportunity.quoted_table_name}.#{Oportunity.qcn('review_code')} ASC"
      ]
    ).references(control_objective_item: :review).page(params[:page])

    respond_to do |format|
      format.html
    end
  end

  # Muestra el detalle de una oportunidad de mejora
  #
  # * GET /oportunities/1
  def show
    @title = t 'oportunity.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.json # show.json.jbuilder
    end
  end

  # Permite ingresar los datos para crear una nueva oportunidad de mejora
  #
  # * GET /oportunities/new
  def new
    @title = t 'oportunity.new_title'
    @oportunity = Oportunity.new(
      :control_objective_item_id => params[:control_objective_item]
    )

    @oportunity.import_users

    respond_to do |format|
      format.html # new.html.erb
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
  def create
    @title = t 'oportunity.new_title'
    @oportunity = Oportunity.list.new(oportunity_params)

    respond_to do |format|
      if @oportunity.save
        flash.notice = t 'oportunity.correctly_created'
        format.html { redirect_to(edit_oportunity_url(@oportunity)) }
      else
        format.html { render :action => :new }
      end
    end
  end

  # Actualiza el contenido de una oportunidad de mejora siempre que cumpla con
  # las validaciones.
  #
  # * PATCH /oportunities/1
  def update
    @title = t 'oportunity.edit_title'

    respond_to do |format|
      Oportunity.transaction do
        if @oportunity.update(oportunity_params)
          flash.notice = t 'oportunity.correctly_updated'
          format.html { redirect_to(edit_oportunity_url(@oportunity)) }
        else
          format.html { render :action => :edit }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'oportunity.stale_object_error'
    redirect_to :action => :edit
  end

  # Deshace la reiteración de la oportunidad
  #
  # * PATCH /oportunities/undo_reiteration/1
  def undo_reiteration
    @oportunity.undo_reiteration

    respond_to do |format|
      format.html { redirect_to(edit_oportunity_url(@oportunity)) }
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
        :control_objective_item_id, :review_code, :title, :description, :answer,
        :audit_comments, :follow_up_date, :state, :organization_date,
        :solution_date, :repeated_of_id, :origination_date, :skip_work_paper,
        :lock_version,
        business_unit_ids: [],
        finding_user_assignments_attributes: [
          :id, :user_id, :process_owner, :responsible_auditor, :_destroy
        ],
        work_papers_attributes: [
          :id, :name, :code, :number_of_pages, :description, :_destroy,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_answers_attributes: [
          :answer, :commitment_date, :user_id,
          :notify_users, :_destroy, file_model_attributes: [:file, :file_cache]
        ],
        finding_relations_attributes: [
          :id, :description, :related_finding_id, :_destroy
        ],
        taggings_attributes: [
          :id, :tag_id, :_destroy
        ]
      )
    end

    def load_privileges
      @action_privileges.update(
        :auto_complete_for_tagging => :read,
        :auto_complete_for_finding_relation => :read,
        :auto_complete_for_control_objective_item => :read,
        :undo_reiteration => :modify
      )
    end
end
