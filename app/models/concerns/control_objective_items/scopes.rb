module ControlObjectiveItems::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,                    -> { where organization_id: Current.organization&.id }
    scope :not_excluded_from_score, -> { where exclude_from_score: false }
  end

  module ClassMethods
    def with_names(*control_objective_names)
      conditions  = []
      parameters  = {}
      column_name = "#{::ControlObjective.quoted_table_name}.#{::ControlObjective.qcn 'name'}"

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
        conditions << "LOWER(#{column_name}) LIKE :pc_#{i}"
        parameters[:"pc_#{i}"] = "%#{process_control_name.mb_chars.downcase}%"
      end

      includes(control_objective: :process_control).
        where(conditions.join(' OR '), parameters).
        references(:process_controls)
    end

    def with_best_practice_names(*best_practice_names)
      conditions  = []
      parameters  = {}
      column_name = "#{BestPractice.quoted_table_name}.#{BestPractice.qcn 'name'}"

      best_practice_names.each_with_index do |best_practice_name, i|
        conditions << "LOWER(#{column_name}) LIKE :bp_#{i}"
        parameters[:"bp_#{i}"] = "%#{best_practice_name.mb_chars.downcase}%"
      end

      includes(control_objective: { process_control: :best_practice }).
        where(conditions.join(' OR '), parameters).
        references(:best_practices)
    end

    def for_business_units *business_unit_ids
      if business_unit_ids.present?
        conditions = [
          "#{BusinessUnitScore.quoted_table_name}.#{BusinessUnitScore.qcn 'business_unit_id'} IN (:bu_ids)",
          "#{PlanItem.quoted_table_name}.#{PlanItem.qcn 'business_unit_id'} IN (:bu_ids)"
        ].join(' OR ')

        includes(:business_unit_scores, review: :plan_item).
          where("(#{conditions})", bu_ids: business_unit_ids).
          references(:business_unit_scores, :plan_items)
      else
        all
      end
    end

    def list_with_final_review
      includes(:review).merge Review.list_with_final_review
    end

    def by_issue_date operator, date, date_until = nil
      mask      = operator.downcase == 'between' && date_until ? '? AND ?' : '?'
      condition = "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} #{operator} #{mask}"

      includes(review: :conclusion_final_review).where condition, *[date, date_until].compact
    end

    def by_business_unit_type business_unit_type_id
      includes(review: { plan_item: :business_unit }).
        where(business_units: { business_unit_type_id: business_unit_type_id }).
        references :business_units
    end
  end
end
