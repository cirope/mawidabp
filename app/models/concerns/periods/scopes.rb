module Periods::Scopes
  extend ActiveSupport::Concern

  module ClassMethods
    def list
      where(organization_id: Organization.current_id).order 'number DESC'
    end

    def list_by_date from_date, to_date
      list.where(
        [
          "#{quoted_table_name}.#{qcn('start')} BETWEEN :from_date AND :to_date",
          "#{quoted_table_name}.#{qcn('end')} BETWEEN :from_date AND :to_date"
        ].join(' OR '), { from_date: from_date, to_date: to_date }
      ).reorder order_by_dates
    end

    def currents
      list.where(
        [
          "#{quoted_table_name}.#{qcn('start')} <= :today", "#{quoted_table_name}.#{qcn('end')} >= :today"
        ].join(' AND '), { today: Date.today }
      ).reorder order_by_dates
    end

    def list_all_without_plans
      list.includes(:plans).where(plans: { period_id: nil }).
        reorder(order_by_dates).references(:plans)
    end

    private

      def order_by_dates
        ["#{quoted_table_name}.#{qcn('start')} ASC", "#{quoted_table_name}.#{qcn('end')} ASC"]
      end
  end
end
