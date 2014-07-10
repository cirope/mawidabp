module Periods::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      where(organization_id: Organization.current_id).order 'number DESC'
    }
    scope :list_by_date, ->(from_date, to_date) {
      list.where(
        [
          "#{table_name}.start BETWEEN :from_date AND :to_date",
          "#{table_name}.end BETWEEN :from_date AND :to_date"
        ].join(' OR '), { from_date: from_date, to_date: to_date }
      ).reorder(["#{table_name}.start ASC", "#{table_name}.end ASC"])
    }
    scope :currents, -> {
      list.where(
        [
          "#{table_name}.start <= :today", "#{table_name}.end >= :today"
        ].join(' AND '), { today: Date.today }
      ).reorder(["#{table_name}.start ASC", "#{table_name}.end ASC"])
    }
    scope :list_all_without_plans, -> {
      list.includes(:plans).where(
        "#{Plan.table_name}.period_id IS NULL"
      ).reorder(["#{table_name}.start ASC", "#{table_name}.end ASC"]).references(
        :plans
      )
    }
    scope :list_all_without_procedure_controls, -> {
      list.includes(:procedure_controls).where(
        "#{ProcedureControl.table_name}.period_id IS NULL"
      ).order(["#{table_name}.start ASC", "#{table_name}.end ASC"]).references(
        :procedure_controls
      )
    }
  end
end
