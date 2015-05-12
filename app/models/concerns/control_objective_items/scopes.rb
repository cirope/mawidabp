module ControlObjectiveItems::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,                    -> { where organization_id: Organization.current_id }
    scope :not_excluded_from_score, -> { where(exclude_from_score: false) }
  end

  module ClassMethods
    def with_names(*control_objective_names)
      conditions = []
      parameters = {}

      control_objective_names.each_with_index do |control_objective_name, i|
        conditions << "LOWER(#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn('name')}) LIKE :co_#{i}"
        parameters[:"co_#{i}"] = "%#{control_objective_name.mb_chars.downcase}%"
      end

      includes(:control_objective).where(conditions.join(' OR '), parameters).references(:control_objectives)
    end
  end
end
