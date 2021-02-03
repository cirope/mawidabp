module Periods::Scopes
  extend ActiveSupport::Concern

  module ClassMethods
    def list
      where(organization_id: Current.organization&.id).order name: :desc
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
      list.includes(:plan).where(plans: { period_id: nil }).
        reorder(order_by_dates).references(:plans)
    end

    def list_all_with_plans current_period = nil
      result = []
      period = current_period == 'current' ? currents : Period.list

      period.map do |r|
        result << r if PlanItem.list_unused(r.id).any?
      end

      result
    end

    private

      def order_by_dates
        [
          "#{quoted_table_name}.#{qcn('start')} DESC",
          "#{quoted_table_name}.#{qcn('end')} DESC"
        ].map { |o| Arel.sql o }
      end
  end
end
