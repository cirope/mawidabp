# frozen_string_literal: true

module AutoCompleteFor::ControlObjectiveAuditor
  extend ActiveSupport::Concern

  def auto_complete_for_control_objective_auditor
    conditions = prepare_search(
      model: User,
      raw_query: params[:q],
      columns: ::User::COLUMNS_FOR_SEARCH.keys
    )[:conditions]

    control_objective = ControlObjective.list.find params[:control_objective_id]
    excluded_ids      = control_objective.control_objective_auditors.map { |coa| coa.user.id }

    @users = User.list.include_tags.where.not(id: excluded_ids).auditors.not_hidden.where(conditions).limit(10)

    respond_to do |format|
      format.js { render template: 'control_objectives/auto_complete_for_control_objective_auditor.json' }
    end
  end
end
