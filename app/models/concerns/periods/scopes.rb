module Periods::Scopes
  extend ActiveSupport::Concern

  module ClassMethods
    def list
      where(organization_id: Organization.current_id).order 'number DESC'
    end

    def list_by_date from_date, to_date
      list.where(
        [
          "#{table_name}.start BETWEEN :from_date AND :to_date",
          "#{table_name}.end BETWEEN :from_date AND :to_date"
        ].join(' OR '), { from_date: from_date, to_date: to_date }
      ).reorder order_by_dates
    end

    def currents
      list.where(
        [
          "#{table_name}.start <= :today", "#{table_name}.end >= :today"
        ].join(' AND '), { today: Date.today }
      ).reorder order_by_dates
    end

    def list_all_without_plans
      list.includes(:plans).where(plans: { period_id: nil }).
        reorder(order_by_dates).references(:plans)
    end

    private

      def order_by_dates
        ["#{table_name}.start ASC", "#{table_name}.end ASC"]
      end
  end
end
