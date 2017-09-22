module Weaknesses::Scopes
  extend ActiveSupport::Concern

  included do
    scope :with_highest_risk, -> {
      where "#{quoted_table_name}.#{qcn 'highest_risk'} = #{quoted_table_name}.#{qcn 'risk'}"
    }

    scope :all_for_report, -> {
      where(
        state: Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).values,
        final: true
      ).order(risk: :desc, state: :asc)
    }
  end

  module ClassMethods
    def with_medium_risk risk_delta = 1
      where "#{quoted_table_name}.#{qcn 'risk'} = (#{quoted_table_name}.#{qcn 'highest_risk'} - #{risk_delta})"
    end

    def by_risk risk
      where risk: risk
    end
  end
end
