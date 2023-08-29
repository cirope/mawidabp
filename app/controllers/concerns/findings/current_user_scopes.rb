module Findings::CurrentUserScopes
  extend ActiveSupport::Concern

  def current_user_findings
    set_selected_user
    set_descendants
    set_related_users

    build_current_user_query_conditions
    filtered_current_user_findings
  end

  private

    def set_selected_user
      @selected_user     = User.find params[:user_id] if params[:user_id]
      @selected_user_ids = params[:user_ids] if params[:user_ids].present?
    end

    def set_descendants
      @self_and_descendants = @auth_user.descendants + [@auth_user]
    end

    def set_related_users
      @related_users = @auth_user.related_users_and_descendants
    end

    def build_current_user_query_conditions
      conditions = { final: false }

      if should_show_all?
        conditions.merge! by_selected_user_conditions
      else
        conditions.merge! by_self_and_descendants_conditions
      end

      conditions.merge! by_owner_conditions
      conditions.merge! by_pending_to_endorsement_conditions
      conditions.merge! by_id_or_state_conditions

      build_search_conditions Finding, conditions
    end

    def should_show_all?
      corporate_not_audited = current_organization.corporate? &&
                              !@auth_user.can_act_as_audited?

      corporate_not_audited   ||
        @auth_user.committee? ||
        @selected_user        ||
        @selected_user_ids
    end

    def by_selected_user_conditions
      conditions = {}

      if @selected_user
        conditions[User.table_name] = { id: @selected_user.id }

        if params[:as_responsible]
          conditions[FindingUserAssignment.table_name] = { responsible_auditor: true }
        end
      elsif @selected_user_ids
        conditions[User.table_name] = { id: @selected_user_ids }
      end

      conditions
    end

    def by_self_and_descendants_conditions
      allowed_ids = @self_and_descendants.map(&:id) + @related_users.map(&:id)
      ids         = if allowed_ids.include?(@selected_user&.id)
                      @selected_user.id
                    else
                      allowed_ids
                    end

      { User.table_name => { id: ids } }
    end

    def by_owner_conditions
      conditions = {}

      if params[:as_owner].present?
        conditions[FindingUserAssignment.table_name] = { process_owner: true }

        if current_organization.corporate?
          conditions.merge! by_self_and_descendants_conditions
        end
      end

      conditions
    end

    def by_pending_to_endorsement_conditions
      conditions = {}

      if params[:pending_to_endorsement].present?
        conditions[FindingAnswer.table_name] =
          { Endorsement.table_name =>
            {
              status: Endorsement.statuses['pending'],
              user_id: @auth_user.id
            } }
      end

      conditions
    end

    def by_id_or_state_conditions
      conditions = {}

      if params[:ids]
        conditions[:id] = params[:ids]
      else
        conditions[:state] = case params[:completion_state]
                             when 'incomplete'
                               incomplete_status_list
                             when 'repeated'
                               repeated_status_list
                             else
                               completed_status_list
                             end
      end

      conditions
    end

    def incomplete_status_list
      Finding::PENDING_STATUS - [Finding::STATUS[:incomplete]]
    end

    def repeated_status_list
      [Finding::STATUS[:repeated]]
    end

    def completed_status_list
      Finding::STATUS.values         -
        Finding::PENDING_STATUS      -
        [Finding::STATUS[:revoked]]  -
        [Finding::STATUS[:repeated]]
    end

    def filtered_current_user_findings
      scope = scoped_findings.
        includes(*current_user_includes).
        left_joins(current_user_left_joins).
        merge(
          PlanItem.allowed_by_business_units_and_auxiliar_business_units_types
        )
      if @extra_query_values
        # Evitamos el `includes` para no tener los alias de tablas relacionadas
        # en el `select` de la query, de esta forma no necesitamos hacer
        # GROUP BY por cada tabla incluida.
        includes = scope.values[:includes]
        scope    = scope.unscope(:includes).left_joins(*includes) if includes.present?

        @extra_query_values.each do |method, args|
          scope = scope.send method, args
        end
      end

      scope.where(@conditions).
        order(@order_by || current_user_default_sort_columns).
        references(*current_user_references)
    end

    def deep_to_a(value)
      # Helper para transformar todos los includes/joins
      # a un array para poder iterarlos.
      return [value] unless value.respond_to?(:to_a)

      value.to_a.map { |v| deep_to_a(v) }
    end

    def current_user_includes
      [
        {
          control_objective_item: {
            review: [:conclusion_final_review, :period, :plan_item]
          },
          review: :conclusion_draft_review,
        },
        :organization,
        :taggings,
        :tags,
        :work_papers
      ]
    end

    def current_user_left_joins
      [
        :users,
        ({ finding_answers: [:endorsements] } if params[:pending_to_endorsement].present?)
      ].compact
    end

    def current_user_default_sort_columns
      [
        current_user_first_sort_column,
        "#{Finding.quoted_table_name}.#{Finding.qcn('organization_id')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('state')} ASC",
        "#{Finding.quoted_table_name}.#{Finding.qcn('review_code')} ASC"
      ].map { |o| Arel.sql o }
    end

    def current_user_references
      [:users, :control_objective_items, :reviews, :finding_user_assignments]
    end

    def current_user_first_sort_column
      if params[:completion_state] == 'incomplete'
        "#{Finding.quoted_table_name}.#{Finding.qcn 'follow_up_date'} ASC"
      else
        "#{Finding.quoted_table_name}.#{Finding.qcn 'solution_date'} DESC"
      end
    end
end
