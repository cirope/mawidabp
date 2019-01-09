module Findings::ReportScopes
  extend ActiveSupport::Concern

  included do
    scope :awaiting,          -> { where state: Finding::STATUS[:awaiting] }
    scope :being_implemented, -> { where state: Finding::STATUS[:being_implemented] }
    scope :implemented,       -> { where state: Finding::STATUS[:implemented] }
    scope :not_incomplete,    -> { where "state <> ?", Finding::STATUS[:incomplete] }
    scope :internal_audit,    -> { with_business_unit_external false }
    scope :external_audit,    -> { with_business_unit_external true }
    scope :with_status_for_report, -> {
      where state: Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).values
    }
  end

  module ClassMethods
    def for_period period
      includes(control_objective_item: { review: :period }).where(
        "#{Period.table_name}.id" => period.id
      ).references(:periods)
    end

    def list_all_by_date from_date, to_date, order
      list.includes(
        review: [:period, :conclusion_final_review, {plan_item: :business_unit}]
      ).where(
        "#{ConclusionReview.table_name}.issue_date" => from_date..to_date
      ).references(:conslusion_reviews, :periods).order(
        order && [
          "#{Period.quoted_table_name}.#{Period.qcn('start')} ASC",
          "#{Period.quoted_table_name}.#{Period.qcn('end')} ASC"
        ].map { |o| Arel.sql o }
      )
    end

    def list_all_in_execution_by_date from_date, to_date
      list.includes(
        control_objective_item: { review: [:period, :conclusion_final_review] }
      ).where(
        [
          "#{Review.quoted_table_name}.#{Review.qcn('created_at')} BETWEEN :begin AND :end",
          "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn('review_id')} IS NULL"
        ].join(' AND '),
        { begin: from_date, end: to_date }
      ).references(:reviews, :periods, :conclusion_reviews)
    end

    def with_solution_date_between from_date, to_date
      where "#{table_name}.solution_date" => from_date..to_date
    end

    def with_business_unit_external external
      includes(
        control_objective_item: {
          review: {
            plan_item: { business_unit: :business_unit_type }
          }
        }
      ).where(
        "#{BusinessUnitType.table_name}.external" => external
      ).references(:business_unit_types)
    end

    def for_user user_id
      includes(:finding_user_assignments).
        where(finding_user_assignments: { user_id: user_id }).
        references(:finding_user_assignments)
    end

    def for_business_unit business_unit_id
      conditions = [
        "#{PlanItem.quoted_table_name}.#{PlanItem.qcn 'business_unit_id'} = :bu_id",
        "#{BusinessUnitFinding.quoted_table_name}.#{BusinessUnitFinding.qcn 'business_unit_id'} = :bu_id"
      ].join ' OR '

      includes({ control_objective_item: { review: :plan_item } }, :business_unit_findings).
        where("(#{conditions})", bu_id: business_unit_id).
        references(:plan_items, :business_unit_findings)
    end

    def for_process_control process_control_id
      includes(control_objective_item: :control_objective).
        where(control_objectives: { process_control_id: process_control_id }).
        references(:control_objectives)
    end
  end
end
