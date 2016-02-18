module ControlObjectiveItems::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,                    -> { where organization_id: Organization.current_id }
    scope :not_excluded_from_score, -> { where(exclude_from_score: false) }
  end

  module ClassMethods
    def with_names(*control_objective_names)
      conditions  = []
      parameters  = {}
      column_name = "#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn 'name'}"

      control_objective_names.each_with_index do |control_objective_name, i|
        conditions << "LOWER(#{column_name}) LIKE :co_#{i}"
        parameters[:"co_#{i}"] = "%#{control_objective_name.mb_chars.downcase}%"
      end

      includes(:control_objective).
        where(conditions.join(' OR '), parameters).
        references(:control_objectives)
    end

    def with_process_control_names(*process_control_names)
      conditions  = []
      parameters  = {}
      column_name = "#{ProcessControl.quoted_table_name}.#{ProcessControl.qcn 'name'}"

      process_control_names.each_with_index do |process_control_name, i|
        conditions << "LOWER(#{column_name}) LIKE :co_#{i}"
        parameters[:"co_#{i}"] = "%#{process_control_name.mb_chars.downcase}%"
      end

      includes(control_objective: :process_control).
        where(conditions.join(' OR '), parameters).
        references(:process_controls)
    end
  end
end
