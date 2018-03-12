module PlanItems::Scopes
  extend ActiveSupport::Concern

  included do
    scope :with_business_unit, -> { where.not business_unit_id: nil }
    scope :list, -> {
      joins(:plan).where plans: { organization_id: Organization.current_id }
    }
  end

  module ClassMethods
    def list_unused period_id
      left_joins(:review, :plan).
        where(plans: { period_id: period_id }, reviews: { plan_item_id: nil }).
        where.not(business_unit_id: nil).
        references(:plans, :reviews).
        order(project: :asc)
    end

    def for_business_unit_type business_unit_type
      if business_unit_type.to_i > 0
        condition = { business_units: { business_unit_type_id: business_unit_type.to_i } }
      else
        condition = { business_units: { business_unit_type_id: nil } }
      end

      left_joins(:business_unit).
        where(condition).
        order(order_number: :asc).
        references(:business_units)
    end

    def for_period period
      joins(:plan).where plans: { period_id: period.id }
    end

    def between _start, _end
      condition = [
        "#{quoted_table_name}.#{qcn('start')} >= :start",
        "#{quoted_table_name}.#{qcn('end')} <= :end"
      ].join(' AND ')

      where condition, start: _start, end: _end
    end
  end
end
