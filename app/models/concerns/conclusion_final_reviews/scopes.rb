module ConclusionFinalReviews::Scopes
  extend ActiveSupport::Concern

  included do
    scope :next_to_expire, -> {
      date  = CONCLUSION_FINAL_REVIEW_EXPIRE_DAYS.days.from_now_in_business.to_date
      range = if date.wday == 5
                date..(date + 2.days)
              else
                date
              end

      where close_date: range
    }
  end

  module ClassMethods
    def ordered
      includes(
        review: { plan_item: { business_unit: :business_unit_type } }
      ).references(:business_unit_types).order(
        [
          "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('external')} ASC",
          "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('name')} ASC",
          "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn('issue_date')}"
        ].map { |o| Arel.sql o }
      )
    end

    def list_all_by_date from, to
      list.where issue_date: from..to
    end

    def list_all_by_solution_date from, to
      list_all_with_weaknesses_solution_date from, to
    end

    def list_all_by_final_solution_date from, to
      list_all_with_weaknesses_solution_date from, to, relation: :final_weaknesses
    end

    def with_near_close_date
      ConclusionFinalReview.next_to_expire
    end

    def internal_audit
      with_external_business_unit_type_as false
    end

    def external_audit
      with_external_business_unit_type_as true
    end

    private

      def list_all_with_weaknesses_solution_date from, to, relation: :weaknesses
        list.includes(
          review: [
            { plan_item: { business_unit: :business_unit_type } },
            { control_objective_items: relation }
          ]
        ).where(Weakness.table_name => {
          solution_date: from..to
        }).references(:findings, :business_unit_types, :weaknesses).order(
          [
            "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('external')} ASC",
            "#{BusinessUnitType.quoted_table_name}.#{BusinessUnitType.qcn('name')} ASC",
            "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn('issue_date')}"
          ].map { |o| Arel.sql o }
        )
      end

      def with_external_business_unit_type_as external
        includes(
          review: { plan_item: { business_unit: :business_unit_type } }
        ).where(business_unit_types: { external: external }).references(
          :business_unit_types
        )
      end
  end
end
