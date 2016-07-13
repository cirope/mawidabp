class FindingsController < ApplicationController
  include AutoCompleteFor::FindingRelation

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_finding, only: [:show, :edit, :update]
  layout proc { |controller| controller.request.xhr? ? false : 'application' }

  # Lista las debilidades y oportunidades
  #
  # * GET /findings
  def index
    @title = t 'finding.index_title'
    @selected_user = User.find(params[:user_id]) if params[:user_id]
    @self_and_descendants = @auth_user.descendants + [@auth_user]
    @related_users = @auth_user.related_users_and_descendants
    default_conditions = { final: false }
    corporate_not_audited = current_organization.corporate? && !@auth_user.can_act_as_audited?
    show_all = corporate_not_audited || @auth_user.committee? || @selected_user
    default_sort_column = params[:completed] == 'incomplete' ?
      "#{Finding.quoted_table_name}.#{Finding.qcn('follow_up_date')} ASC" :
      "#{Finding.quoted_table_name}.#{Finding.qcn('solution_date')} DESC"

    if show_all
      if @selected_user
        default_conditions[User.table_name] = { :id => params[:user_id] }

        if params[:as_responsible]
          default_conditions[FindingUserAssignment.table_name] = { :responsible_auditor => true }
        end
      end
    else
      self_and_descendants_ids = @self_and_descendants.map(&:id) + @related_users.map(&:id)
      default_conditions[User.table_name] = {
        :id => self_and_descendants_ids.include?(@selected_user.try(:id)) ?
          @selected_user.id : self_and_descendants_ids
      }
    end

    if params[:as_owner]
      default_conditions[FindingUserAssignment.table_name] = { :process_owner => true }

      if current_organization.corporate?
        self_and_descendants_ids = @self_and_descendants.map(&:id) + @related_users.map(&:id)
        default_conditions[User.table_name] = {
          :id => self_and_descendants_ids.include?(@selected_user.try(:id)) ?
            @selected_user.id : self_and_descendants_ids
        }
      end
    end

    if params[:ids]
      default_conditions[:id] = params[:ids]
    else
      default_conditions[:state] = params[:completed] == 'incomplete' ?
        Finding::PENDING_STATUS - [Finding::STATUS[:incomplete]] :
        Finding::STATUS.values - Finding::PENDING_STATUS - [Finding::STATUS[:revoked]] + [nil]
    end

    build_search_conditions Finding, default_conditions

    @findings = scoped_findings.includes(
      {
        :control_objective_item => {
          :review => [:conclusion_final_review, :period, :plan_item]
        }
      }, :users
    ).where(@conditions).order(
      @order_by || [
        default_sort_column,
        "#{Finding.quoted_table_name}.#{Finding.qcn('organization_id')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('state')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ]
   ).references(:users, :control_objective_items, :reviews, :finding_user_assignments)

    respond_to do |format|
      format.html {
        @findings = @findings.page(params[:page])

        if @findings.count == 1 && !@query.blank? && !params[:page]
          redirect_to finding_url(params[:completed], @findings.first)
        end
      } # index.html.erb
      format.csv { render csv: @findings.to_csv(params[:completed]), filename: @title.downcase }
    end
  end

  # Muestra el detalle de una debilidad u oportunidad
  #
  # * GET /findings/1
  # * GET /findings/1.xml
  def show
    @title = t 'finding.show_title'

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @finding }
    end
  end

  # Recupera los datos para modificar una debilidad u oportunidad
  #
  # * GET /findings/1/edit
  def edit
    @title = t 'finding.edit_title'

    if @finding.nil? ||
        (@auth_user.can_act_as_audited? && !@finding.users.include?(@auth_user))
      redirect_to findings_url
    end
  end

  # Actualiza el contenido de una debilidad u oportunidad siempre que cumpla con
  # las validaciones. Además actualiza el contenido de las respuestas que la
  # componen.
  #
  # * PATCH /findings/1
  # * PATCH /findings/1.xml
  def update
    @title = t 'finding.edit_title'

    if @finding.nil? ||
        (@auth_user.can_act_as_audited? && !@finding.users.include?(@auth_user))
      raise 'Finding can not be updated'
    end

    # Los auditados no pueden modificar desde observaciones las asociaciones
    if @auth_user.can_act_as_audited?
      params[:finding].delete :finding_user_assignments_attributes
    end

    prepare_parameters

    respond_to do |format|
      Finding.transaction do
        if @finding.update(finding_params)
          flash.notice = t 'finding.correctly_updated'
          format.html { redirect_to(edit_finding_url(params[:completed], @finding)) }
          format.xml  { head :ok }
        else
          flash.alert = t 'finding.stale_object_error'
          format.html { render :action => :edit }
          format.xml  { render :xml => @finding.errors, :status => :unprocessable_entity }
          raise ActiveRecord::Rollback
        end
      end
    end

  rescue ActiveRecord::StaleObjectError
    flash.alert = t 'finding.stale_object_error'
    redirect_to :action => :edit
  end

  # Crea el documento de seguimiento de la oportunidad
  #
  # * GET /oportunities/follow_up_pdf/1
  def follow_up_pdf
    finding = scoped_findings.find_by(id: params[:id])

    finding.follow_up_pdf(current_organization)

    redirect_to finding.relative_follow_up_pdf_path
  end

  private

    def set_finding
      includes = [{:control_objective_item => {:review => :period}}]
      conditions = { :id => params[:id], :final => false }

      if !current_organization.corporate && @auth_user.can_act_as_audited?
        includes << :users
        conditions[User.table_name] = {
          :id => @auth_user.descendants.map(&:id) +
            @auth_user.related_users_and_descendants.map(&:id) + [@auth_user.id]
        }
      end

      conditions[:state] = Finding::STATUS.values - [Finding::STATUS[:incomplete]] + [nil]

      @finding = Finding.includes(includes).where(conditions).references(
        :periods, :organizations
      ).first

      # TODO: eliminar cuando se corrija el problema que hace que include solo
      # traiga el primer usuario
      @finding.try(:reload)

      @finding.finding_prefix = true if @finding
    end

    def finding_params
      params.require(:finding).permit(
        :id, :control_objective_item_id, :review_code, :title, :description,
        :answer, :audit_comments, :state, :origination_date, :solution_date,
        :audit_recommendations, :effect, :risk, :priority, :follow_up_date,
        :nested_user, :lock_version,
        users_for_notification: [],
        business_unit_ids: [],
        finding_user_assignments_attributes: [
          :id, :user_id, :process_owner, :responsible_auditor, :_destroy
        ],
        work_papers_attributes: [
          :id, :name, :code, :number_of_pages, :description, :_destroy, :lock_version,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_answers_attributes: [
          :id, :answer, :auditor_comments, :user_id, :commitment_date, :notify_users, :_destroy,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_relations_attributes: [
          :id, :description, :related_finding_id, :_destroy
        ],
        costs_attributes: [
          :id, :raw_cost, :cost, :cost_type, :description, :user_id, :_destroy
        ],
        comments_attributes: [
          :user_id, :comment
        ]
      )
    end

    def prepare_parameters
      if @auth_user.can_act_as_audited?
        params[:finding].delete_if do |k,|
          ![:finding_answers_attributes, :costs_attributes].include?(k.to_sym)
        end
      end
    end

    def load_privileges
      @action_privileges.update(
        :follow_up_pdf => :read,
        :auto_complete_for_finding_relation => :read
      )
    end

    def scoped_findings
      current_organization.corporate? ? Finding.group_list : Finding.list
    end
end
