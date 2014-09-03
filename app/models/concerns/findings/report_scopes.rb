module Findings::ReportScopes
  extend ActiveSupport::Concern

  included do
    scope :being_implemented, -> { where state: Finding::STATUS[:being_implemented] }
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
        order && ["#{Period.table_name}.start ASC", "#{Period.table_name}.end ASC"]
      )
    end

    def list_all_in_execution_by_date from_date, to_date
      list.includes(
        control_objective_item: { review: [:period, :conclusion_final_review] }
      ).where(
        [
          "#{Review.table_name}.created_at BETWEEN :begin AND :end",
          "#{ConclusionFinalReview.table_name}.review_id IS NULL"
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
  end
end
