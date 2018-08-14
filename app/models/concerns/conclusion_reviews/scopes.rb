module ConclusionReviews::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Current.organization&.id }
  end

  module ClassMethods
    def for_period period
      includes(review: :period).
        where(periods: { id: period.id }).
        references(:periods)
    end

    def for_month month
      from = month.at_beginning_of_month
      to   = month.at_end_of_month

      where(issue_date: from..to)
    end

    def by_best_practice_names *best_practice_names
      conditions  = []
      parameters  = {}
      column_name = "#{BestPractice.quoted_table_name}.#{BestPractice.qcn 'name'}"

      best_practice_names.each_with_index do |best_practice_name, i|
        conditions << "LOWER(#{column_name}) LIKE :bp_#{i}"
        parameters[:"bp_#{i}"] = "%#{best_practice_name.mb_chars.downcase}%"
      end

      includes(review: { control_objective_items: { control_objective: { process_control: :best_practice } } }).
        where(conditions.join(' OR '), parameters).
        references(:best_practices)
    end

    def by_control_objective_names *control_objective_names
      conditions  = []
      parameters  = {}
      column_name = "#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn 'name'}"

      control_objective_names.each_with_index do |control_objective_name, i|
        conditions << "LOWER(#{column_name}) LIKE :co_#{i}"
        parameters[:"co_#{i}"] = "%#{control_objective_name.mb_chars.downcase}%"
      end

      includes(review: { control_objective_items: :control_objective }).
        where(conditions.join(' OR '), parameters).
        references(:control_objectives)
    end

    def by_process_control_names *process_control_names
      conditions  = []
      parameters  = {}
      column_name = "#{ProcessControl.quoted_table_name}.#{ProcessControl.qcn 'name'}"

      process_control_names.each_with_index do |process_control_name, i|
        conditions << "LOWER(#{column_name}) LIKE :pc_#{i}"
        parameters[:"pc_#{i}"] = "%#{process_control_name.mb_chars.downcase}%"
      end

      includes(review: { control_objective_items: { control_objective: :process_control } }).
        where(conditions.join(' OR '), parameters).
        references(:process_controls)
    end

    def by_business_unit_type business_unit_type_id
      ids_by_review = includes(review: { plan_item: :business_unit }).
        where(business_units: { business_unit_type_id: business_unit_type_id }).
        references(:business_units).pluck('id')

      ids_by_control_objectives = includes(business_unit_includes).
        where(business_units: { business_unit_type_id: business_unit_type_id }).
        references(:business_units)

      where(id: ids_by_control_objectives | ids_by_review)
    end

    def by_business_unit_names(*business_unit_names)
      conditions, parameters = business_unit_conditions business_unit_names

      ids_by_control_objectives = includes(business_unit_includes).where(
        conditions.join(' OR '), parameters
      ).references(:business_units).pluck('id')

      ids_by_review = includes(plan_item: :business_unit).where(
        conditions.join(' OR '), parameters
      ).references(:business_units).pluck('id')

      where(id: ids_by_control_objectives | ids_by_review)
    end

    private

      def business_unit_conditions business_unit_names
        conditions = []
        parameters = {}

        business_unit_names.each_with_index do |business_unit_name, i|
          conditions << "LOWER(#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn 'name'}) LIKE :bu_#{i}"
          parameters[:"bu_#{i}"] = "%#{business_unit_name.mb_chars.downcase}%"
        end

        [conditions, parameters]
      end

      def business_unit_includes
        {
          review: {
            control_objective_items: { business_unit_scores: :business_unit }
          }
        }
      end
  end
end
