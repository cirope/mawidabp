class FindingsController < ApplicationController
  include AutoCompleteFor::FindingRelation
  include AutoCompleteFor::Tagging
  include Findings::CurrentUserScopes
  include Findings::SetFinding
  include Reports::FileResponder

  respond_to :html

  before_action :auth, :load_privileges, :check_privileges
  before_action :set_finding, only: [:show, :edit, :update]
  before_action :check_if_editable, only: [:edit, :update]
  before_action :set_title, except: [:destroy]

  # * GET /incomplete/findings
  def index
    @findings = current_user_findings

    respond_to do |format|
      format.html { paginate_findings }
      format.csv  { render_index_csv }
      format.pdf  { redirect_to pdf.relative_path }
    end
  end

  # * GET /incomplete/findings/1
  def show
  end

  # * GET /incomplete/findings/1/edit
  def edit
  end

  # * PATCH /incomplete/findings/1
  def update
    update_resource @finding, finding_params

    location = if @finding.invalid? || @finding.reload.pending?
                 edit_finding_url params[:completion_state], @finding
               else
                 finding_url 'complete', @finding
               end

    respond_with @finding, location: location unless performed?
  end

  private

    def finding_params
      casted_params = if @auth_user.can_act_as_audited?
                        audited_finding_params
                      else
                        auditor_finding_params
                      end

      casted_params.merge(
        can_close_findings: USE_SCOPE_CYCLE && can_perform?(:approval)
      )
    end

    def auditor_finding_params
      params.require(:finding).permit(
        :id, :control_objective_item_id, :review_code, :title, :description,
        :brief, :answer, :current_situation, :current_situation_verified,
        :audit_comments, :state, :origination_date, :solution_date,
        :audit_recommendations, :effect, :risk, :priority, :follow_up_date,
        :compliance, :impact_risk, :probability, :compliance_observations,
        :manual_risk, :nested_user, :skip_work_paper, :use_suggested_impact,
        :use_suggested_probability, :impact_amount, :probability_amount,
        :extension, :risk_justification, :lock_version,
        :year, :nsisio, :nobs,
        impact: [],
        operational_risk: [],
        internal_control_components: [],
        users_for_notification: [],
        business_unit_ids: [],
        tag_ids: [],
        finding_user_assignments_attributes: [
          :id, :user_id, :process_owner, :responsible_auditor, :_destroy
        ],
        work_papers_attributes: [
          :id, :name, :code, :number_of_pages, :description, :_destroy, :lock_version,
          file_model_attributes: [:id, :file, :file_cache]
        ],
        finding_answers_attributes: [
          :id, :answer, :user_id, :notify_users,
          file_model_attributes: [:file, :file_cache],
          endorsements_attributes: [:id, :status, :user_id, :_destroy]
        ],
        finding_relations_attributes: [
          :id, :description, :related_finding_id, :_destroy
        ],
        issues_attributes: [
          :id, :customer, :entry, :operation, :amount, :currency, :comments,
          :close_date, :_destroy
        ],
        tasks_attributes: [
          :id, :code, :description, :status, :due_on, :_destroy
        ],
        taggings_attributes: [
          :id, :tag_id, :_destroy
        ],
        costs_attributes: [
          :id, :raw_cost, :cost, :cost_type, :description, :user_id, :_destroy
        ],
        comments_attributes: [
          :user_id, :comment
        ]
      )
    end

    def audited_finding_params
      params.require(:finding).permit(
        :id, :lock_version,
        finding_answers_attributes: [
          :answer, :user_id, :commitment_date, :notify_users, :skip_commitment_support,
          file_model_attributes: [:file, :file_cache],
          commitment_support_attributes: [:id, :reason, :plan, :controls]
        ],
        costs_attributes: [
          :id, :raw_cost, :cost, :cost_type, :description, :user_id
        ]
      )
    end

    def load_privileges
      @action_privileges.update(
        auto_complete_for_tagging: :read,
        auto_complete_for_finding_relation: :read
      )
    end

    def pdf
      title_partial = case params[:completion_state]
                      when'incomplete'
                        'pending'
                      when 'repeated'
                        'repeated'
                      else
                        'complete'
                      end

      FindingPdf.create(
        title: t("menu.follow_up.#{title_partial}_findings"),
        columns: @columns,
        query: @query,
        findings: @findings.except(:limit),
        current_organization: current_organization
      )
    end

    def csv_options
      {
        corporate: current_organization.corporate?
      }
    end

    def check_if_editable
      not_editable = (!@finding.pending? && @finding.valid?) ||
        (@auth_user.can_act_as_audited? && @finding.users.reload.exclude?(@auth_user))

      raise ActiveRecord::RecordNotFound if not_editable
    end

    def render_index_csv
      render_or_send_by_mail(
        collection:  @findings,
        filename:    "#{@title.downcase}.csv",
        method_name: :to_csv,
        options:     csv_options
      )
    end

    def paginate_findings
      @findings = @findings.page params[:page]

      if ORACLE_ADAPTER
        @findings.total_entries = @findings.unscope(
          :group, :order, :select
        ).select(:id).distinct.count
      end

      @findings
    end
end
