module PlanItems::Scopes
  extend ActiveSupport::Concern

  included do
    scope :with_business_unit, -> { where.not business_unit_id: nil }
    scope :list, -> {
      joins(:plan).where plans: { organization_id: Current.organization&.id }
    }
  end

  module ClassMethods
    def list_unused period_id
      left_joins(:review, :plan, :memo)
        .where(plans: { period_id: period_id },
               reviews: { plan_item_id: nil },
               memos: { plan_item_id: nil },
               id: allowed_by_business_units_and_auxiliar_business_units_types_ids)
        .where.not(business_unit_id: nil)
        .references(:plans, :reviews, :memos)
        .order(project: :asc)
    end

    def allowed_by_business_units_and_auxiliar_business_units_types
      where id: allowed_by_business_units_and_auxiliar_business_units_types_ids
    end

    def allowed_by_auxiliar_business_units_types
      business_unit_types = Current.user.business_unit_types

      if business_unit_types.any?
        left_joins(:auxiliar_business_unit_types)
          .where auxiliar_business_unit_types: {
            business_unit_type: business_unit_types
          }
      else
        all
      end
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

    private

      def allowed_by_business_units_and_auxiliar_business_units_types_ids
        business_unit_types = Current.user.business_unit_types

        (if business_unit_types.any?
           left_joins(:auxiliar_business_unit_types)
             .where(auxiliar_business_unit_types: {
                      business_unit_type: business_unit_types
                    })
             .or(where(business_unit_id: Current.user.business_units))
         else
           all
         end).pluck :id
      end
  end
end
