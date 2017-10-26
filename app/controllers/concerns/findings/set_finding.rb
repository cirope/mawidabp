module Findings::SetFinding
  extend ActiveSupport::Concern

  private

    def set_finding
      includes   = [{control_objective_item: {review: :period}}]
      left_joins = scope_current_user_findings? ? [:users] : []

      @finding = scoped_findings.
        left_joins(left_joins).
        includes(includes).
        where(find_finding_conditions).
        references(:periods, :organizations).
        take!

      @finding.finding_prefix = true
    end

    def find_finding_conditions
      conditions = { id: params[:id], final: false }

      if scope_current_user_findings?
        user_ids = @auth_user.self_and_descendants.map(&:id) +
                   @auth_user.related_users_and_descendants.map(&:id)

        conditions[User.table_name] = { id: user_ids }
      end

      conditions[:state] = Finding::STATUS.values - [Finding::STATUS[:incomplete]]

      conditions
    end

    def scope_current_user_findings?
      !current_organization.corporate &&
        @auth_user.can_act_as_audited? &&
        !@auth.committee?
    end
end
